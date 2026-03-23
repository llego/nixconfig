{
  modulesPath,
  username,
  inputs,
  config,
  pkgs,
  ...
}: let
  net = config.christiansandbergNetwork;
in {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./../modules/core.nix
    ./../modules/basic-cli.nix
    ./christiansandberg-networking.nix
    ./christiansandberg-networking-variables.nix
    ./../modules/authelia.nix

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

  # Uptime Kuma monitoring tool
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString net.uptimeKumaPort;
      HOST = net.loopbackIP;
    };
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
    environmentFiles = [config.age.secrets.gotify-admin-password.path];
  };

  # Build website from GitHub repo
  christiansandbergNetwork.websitePackage = pkgs.runCommand "christiansandberg-website" {} ''
    mkdir -p $out
    cp -r ${inputs.christiansandberg-website}/* $out/
  '';
}
