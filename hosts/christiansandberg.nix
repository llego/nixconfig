{
  modulesPath,
  username,
  inputs,
  config,
  pkgs,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./../modules/core.nix
    ./../modules/basic-cli.nix
    ./../modules/authelia.nix
    ./../modules/traefik-vps.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./christiansandberg-disk-config.nix
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      "default-address-pools" = [
        {
          base = "172.21.0.0/16";
          size = 24;
        }
      ];
    };
  };
  users.users.${username}.extraGroups = ["docker"];

  # Ensure the traefik Docker network exists with the correct subnet.
  # All stacks reference it as external: true, so it must pre-exist.
  systemd.services.docker-network-traefik = {
    description = "Create traefik Docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.lib.getExe (pkgs.writeShellScriptBin "docker-network-traefik" ''
        ${pkgs.docker}/bin/docker network inspect traefik > /dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create --driver bridge --subnet=172.21.0.0/24 --gateway=172.21.0.1 traefik
      '');
    };
  };

  # Beszel monitoring agent (Tailscale-only)
  services.beszel.agent = {
    enable = true;
    openFirewall = false;
    environmentFile = "/var/lib/beszel-agent/env";
    environment = {
      PORT = "45876";
      # Bind only to Tailscale interface
      HOST = "100.78.37.16"; # christiansandberg Tailscale IP
    };
  };

  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=${username}"];
  };

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 10;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # Cloudflare DDNS for christiansandberg.fi domain (IPv4 only)
  services.cloudflare-ddns = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-ddns-token.path;
    ip4Domains = [ "christiansandberg.fi" ];
    ip6Domains = [];  # Disable IPv6 DDNS
    proxied = "false";
  };

  # Uptime Kuma monitoring tool
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3001";
      HOST = "172.21.0.1";
    };
  };

  # Gotify push notification server
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_PORT = 8079;  # Port 8080 used by Traefik dashboard
      GOTIFY_SERVER_LISTENADDR = "172.21.0.1";
      GOTIFY_DATABASE_DIALECT = "sqlite3";
      GOTIFY_DATABASE_CONNECTION = "data/gotify.db";
      GOTIFY_DEFAULTUSER_NAME = "admin";
      # GOTIFY_DEFAULTUSER_PASS is loaded from environmentFile
      GOTIFY_UPLOADEDIMAGESDIR = "data/images";
      GOTIFY_PLUGINSDIR = "data/plugins";
    };
    environmentFiles = [ config.age.secrets.gotify-admin-password.path ];
  };

  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    firewall = {
      enable = true;
      checkReversePath = false;  # Required for Docker→host routing
      allowedTCPPorts = [ 22 80 443 ];
      # Allow Docker traefik subnet (172.21.0.0/24) to reach host-bound services.
      # These ports are bound to 172.21.0.1 only, so they are unreachable from the public internet.
      extraCommands = ''
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 9091 -j nixos-fw-accept
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 8079 -j nixos-fw-accept
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 3001 -j nixos-fw-accept
        iptables -w -I nixos-fw -p tcp -s 100.123.67.48 --dport 6379 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -w -D nixos-fw -p tcp -s 172.21.0.0/24 --dport 9091 -j nixos-fw-accept 2>/dev/null || true
        iptables -w -D nixos-fw -p tcp -s 172.21.0.0/24 --dport 8079 -j nixos-fw-accept 2>/dev/null || true
        iptables -w -D nixos-fw -p tcp -s 172.21.0.0/24 --dport 3001 -j nixos-fw-accept 2>/dev/null || true
        iptables -w -D nixos-fw -p tcp -s 100.123.67.48 --dport 6379 -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };
}
