{
  modulesPath,
  inputs,
  config,
  ...
}: {
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
    ./christiansandberg-website.nix
    ./gotify.nix
    ./uptime-kuma.nix
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
}
