{
  config,
  inputs,
  lib,
  ...
}: let
  net = config.networkVars;
in {
  imports = ["${inputs.hetzner_ddns}/release/NixOS/nixos_module.nix"];

  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    interfaces.enp1s0.ipv6.addresses = [
      {
        address = "2a01:4f9:c010:803e::1";
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      # Allow crisuflix (via Tailscale) to reach Redis for traefik-kop
      extraCommands = ''
        iptables -w -I nixos-fw -p tcp -s ${net.tailnetIPs.crisuflix} --dport ${toString net.vps.redis.port} -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -w -D nixos-fw -p tcp -s ${net.tailnetIPs.crisuflix} --dport ${toString net.vps.redis.port} -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };

  services.hetzner_ddns = {
    enable = true;
    zones = [
      {
        domain = "cri.su";
        records = [
          {name = "@";}
          {name = "@"; type = "AAAA"; interface = "enp1s0";}
          {name = "*"; type = "AAAA"; interface = "enp1s0";}
        ];
      }
      {
        domain = "christiansandberg.fi";
        records = [{name = "@";} {name = "@"; type = "AAAA"; interface = "enp1s0";}];
      }
      {
        domain = "sandbergs.fi";
        records = [{name = "@";} {name = "@"; type = "AAAA"; interface = "enp1s0";}];
      }
      {
        domain = "crisusandberg.fi";
        records = [{name = "@";} {name = "@"; type = "AAAA"; interface = "enp1s0";}];
      }
      {
        domain = "csandberg.fi";
        records = [{name = "@";} {name = "@"; type = "AAAA"; interface = "enp1s0";}];
      }
    ];
    protections = true;
    api_key = config.age.secrets.hetzner-dns-token.path;
  };

  users.groups.hetzner-ddns = {};
  users.users.hetzner-ddns = {
    isSystemUser = true;
    group = "hetzner-ddns";
  };

  systemd.services.hetzner_ddns.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "hetzner-ddns";
    Group = "hetzner-ddns";
  };
}
