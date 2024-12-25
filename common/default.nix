{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    #./gnome-config.nix
    ./home-manager
    ./locale.nix
    ./niri-config.nix
    ./nix.nix
    ./printer.nix
    ./sand.berg-certificates.nix
    ./stylix
    ./systempackages.nix
    ./wifi-networks.nix
    
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
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

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

}
