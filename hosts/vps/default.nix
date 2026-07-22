{
  modulesPath,
  inputs,
  config,
  pkgs,
  ...
}: let
  net = config.networkVars;
in {
  system.stateVersion = "24.05";

  services.tailscale = {
    authKeyFile = config.age.secrets.tailscale-preauth-vps.path;
    extraSetFlags = [
      "--ssh"
    ];
  };

  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./ddns.nix
    ./reverse-proxy.nix
    ./headscale.nix
    ./authelia-cri.su.nix
    ./../../modules/core
    ./../../modules/basic-cli.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

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

  # Uptime Kuma monitoring tool
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString net.vps.uptimeKuma.port;
      HOST = net.hosts.loopback;
    };
  };

  # Gotify push notification server
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_PORT = net.vps.gotify.port;
      GOTIFY_SERVER_LISTENADDR = net.hosts.loopback;
      GOTIFY_DATABASE_DIALECT = "sqlite3";
      GOTIFY_DATABASE_CONNECTION = "data/gotify.db";
      GOTIFY_DEFAULTUSER_NAME = "admin";
      # GOTIFY_DEFAULTUSER_PASS is loaded from environmentFile
      GOTIFY_UPLOADEDIMAGESDIR = "data/images";
      GOTIFY_PLUGINSDIR = "data/plugins";
    };
    environmentFiles = [config.age.secrets.gotify-admin-password.path];
  };

  # Static website hosting via Static Web Server
  services.static-web-server = let
    website = pkgs.runCommand "christiansandberg-website" {} ''
      mkdir -p $out
      cp -r ${inputs.christiansandberg-website}/* $out/
    '';
  in {
    enable = true;
    listen = "${net.hosts.loopback}:${toString net.vps.website.port}";
    root = "${website}";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      gotify = {
        rule = "Host(`gotify.tailnet.cri.su`)";
        entryPoints = ["websecure"];
        service = "gotify";
        tls.certResolver = "hetzner";
        middlewares = ["tailnet-only"];
      };
      uptime-kuma = {
        rule = "Host(`uptime.cri.su`)";
        entryPoints = ["websecure"];
        service = "uptime-kuma";
        tls.certResolver = "hetzner";
        middlewares = ["authelia-cri-su"];
      };
      # Hetzner-hosted domains
      website = {
        rule = "Host(`christiansandberg.fi`) || Host(`sandbergs.fi`) || Host(`crisusandberg.fi`) || Host(`csandberg.fi`)";
        entryPoints = ["websecure"];
        service = "website";
        tls.certResolver = "hetzner";
      };
      # csandberg.consulting is on deSEC -- needs its own resolver and wildcard cert
      website-consulting = {
        rule = "Host(`csandberg.consulting`)";
        entryPoints = ["websecure"];
        service = "website";
        tls = {
          certResolver = "desec";
          domains = [
            {
              main = "csandberg.consulting";
              sans = ["*.csandberg.consulting"];
            }
          ];
        };
      };
    };

    services = {
      gotify.loadBalancer.servers = [
        {
          url = "http://${net.hosts.loopback}:${toString net.vps.gotify.port}";
        }
      ];
      uptime-kuma.loadBalancer.servers = [
        {
          url = "http://${net.hosts.loopback}:${toString net.vps.uptimeKuma.port}";
        }
      ];
      website.loadBalancer.servers = [
        {
          url = "http://${net.hosts.loopback}:${toString net.vps.website.port}";
        }
      ];
    };
  };
}
