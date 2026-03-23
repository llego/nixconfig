{
  modulesPath,
  username,
  inputs,
  config,
  pkgs,
  ...
}:

let
  net = config.christiansandbergNetwork;
in

{
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./../modules/core.nix
    ./../modules/basic-cli.nix
    ./christiansandberg-network-config.nix
    ./../modules/authelia.nix
    ./../modules/traefik-vps.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./christiansandberg-disk-config.nix
  ];

  # Beszel monitoring agent (Tailscale-only)
  services.beszel.agent = {
    enable = true;
    openFirewall = false;
    environmentFile = "/var/lib/beszel-agent/env";
    environment = {
      PORT = "45876";
      HOST = net.tailscaleIP;
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
    ip4Domains = [ net.domain ];
    ip6Domains = [];  # Disable IPv6 DDNS
    proxied = "false";
  };

  # Uptime Kuma monitoring tool
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString net.uptimeKumaPort;
      HOST = net.loopbackIP;
    };
  };

  # Static website hosting via Static Web Server
  services.static-web-server = {
    enable = true;
    listen = "${net.loopbackIP}:${toString net.websitePort}";  # Only accessible via Traefik
    root = "/var/www/christiansandberg.fi";
  };

  # Gotify push notification server
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_PORT = net.gotifyPort;
      GOTIFY_SERVER_LISTENADDR = net.loopbackIP;
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
      allowedTCPPorts = [ 22 80 443 ];
      # Allow crisuflix (via Tailscale) to reach Redis for traefik-kop
      extraCommands = ''
        iptables -w -I nixos-fw -p tcp -s ${net.crisuflixIP} --dport ${toString net.redisPort} -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -w -D nixos-fw -p tcp -s ${net.crisuflixIP} --dport ${toString net.redisPort} -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };
}
