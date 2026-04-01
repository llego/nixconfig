{
  modulesPath,
  username,
  inputs,
  config,
  pkgs,
  ...
}: let
  net = config.networkVars;
  website = pkgs.runCommand "christiansandberg-website" {} ''
    mkdir -p $out
    cp -r ${inputs.christiansandberg-website}/* $out/
  '';
in {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./networking.nix
    ./authelia-cri.su.nix
    ./../../modules/core

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
  services.static-web-server = {
    enable = true;
    listen = "${net.hosts.loopback}:${toString net.vps.website.port}";
    root = "${website}";
  };
}
