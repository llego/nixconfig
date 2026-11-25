{config, pkgs, ...}: {
  # Jool intercepts before normal forwarding rules, so run it in a separate
  # namespace and filter traffic before it crosses the namespace boundary.
  boot.extraModulePackages = [config.boot.kernelPackages.jool];

  systemd.services.nat64-lab = {
    description = "Isolated NAT64 translator for the IPv6 lab";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "firewall.service"];
    wants = ["network-online.target"];
    path = [pkgs.iproute2 pkgs.iptables pkgs.nftables pkgs.kmod pkgs.jool-cli pkgs.procps pkgs.gnugrep];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      # Refuse to touch existing resources; they may belong to another service.
      if ip netns list | grep -q '^nat64-lab\( \|$\)' || ip link show nat64-host >/dev/null 2>&1 || nft list table inet nat64_lab >/dev/null 2>&1 || [ -n "$(ip -6 route show exact 64:ff9b::/96)" ] || [ -e /run/nat64-lab-owned ]; then
        echo "NAT64 resource already exists; refusing to overwrite it" >&2
        exit 1
      fi
      mkdir /run/nat64-lab-owned
      cleanup() {
        ip -6 route del 64:ff9b::/96 via fd93:6d8c:54c2:64::2 dev nat64-host 2>/dev/null || true
        nft delete table inet nat64_lab 2>/dev/null || true
        ip netns del nat64-lab 2>/dev/null || true
        ip link del nat64-host 2>/dev/null || true
        rmdir /run/nat64-lab-owned 2>/dev/null || true
      }
      trap cleanup EXIT

      # The current generation may add Jool before the next host reboot.
      modprobe -d /run/current-system/kernel-modules jool
      ip netns add nat64-lab
      ip link add nat64-host type veth peer name nat64-peer
      ip link set nat64-peer netns nat64-lab
      ip addr add 10.254.253.1/30 dev nat64-host
      ip -6 addr add fd93:6d8c:54c2:64::1/64 dev nat64-host nodad
      ip link set nat64-host up
      ip -n nat64-lab link set lo up
      ip -n nat64-lab addr add 10.254.253.2/30 dev nat64-peer
      ip -n nat64-lab -6 addr add fd93:6d8c:54c2:64::2/64 dev nat64-peer nodad
      ip -n nat64-lab link set nat64-peer up
      ip -n nat64-lab route add default via 10.254.253.1
      ip -n nat64-lab -6 route add default via fd93:6d8c:54c2:64::1
      ip netns exec nat64-lab sysctl -qw net.ipv4.ip_forward=1
      ip netns exec nat64-lab sysctl -qw net.ipv6.conf.all.forwarding=1
      ip netns exec nat64-lab jool instance add default --netfilter --pool6 64:ff9b::/96
      for proto in tcp udp icmp; do
        ip netns exec nat64-lab jool pool4 add --"$proto" 10.254.253.2 61001-65535
      done

      # UniFi restricts routed NAT64 access by source network. Devices on br0
      # can bypass UniFi with a direct route; the Home network is trusted.
      nft -f - <<'EOF'
      table inet nat64_lab {
        chain forward {
          type filter hook forward priority -5; policy accept;
          iifname "br0" oifname "nat64-host" ip6 daddr 64:ff9b::/96 accept
          iifname "br0" oifname "nat64-host" ip daddr 10.254.253.2 ct state established,related accept
          oifname "nat64-host" drop
          iifname "nat64-host" oifname "br0" ip6 saddr 64:ff9b::/96 accept
          iifname "nat64-host" oifname "br0" ip saddr 10.254.253.2 accept
          iifname "nat64-host" drop
        }
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ip saddr 10.254.253.2 oifname "br0" masquerade
        }
      }
      EOF
      ip -6 route add 64:ff9b::/96 via fd93:6d8c:54c2:64::2 dev nat64-host
      trap - EXIT
    '';
    postStop = ''
      [ -d /run/nat64-lab-owned ] || exit 0
      ip -6 route del 64:ff9b::/96 via fd93:6d8c:54c2:64::2 dev nat64-host 2>/dev/null || true
      nft delete table inet nat64_lab 2>/dev/null || true
      ip netns del nat64-lab 2>/dev/null || true
      ip link del nat64-host 2>/dev/null || true
      rmdir /run/nat64-lab-owned 2>/dev/null || true
    '';
  };
}
