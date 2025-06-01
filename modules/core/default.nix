{
  lib,
  pkgs,
  username,
  hostname,
  ...
}: {
  imports = [
    ./home-manager
    ./locale.nix
    ./nix.nix
    ./systempackages.nix
  ];

  users.users.${username} = {
    isNormalUser = true;
    initialPassword = "12345";
    description = "Christian Sandberg";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  # Allow passwordless sudo for llego
  security.sudo.extraRules = [
    {
      users = ["${username}"];
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }
  ];

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp59s0.useDHCP = lib.mkDefault true;
  };

  # SSH server
  services.openssh.enable = true;

  # Allow unfree packages
  #nixpkgs.config.allowUnfree = true;
}
