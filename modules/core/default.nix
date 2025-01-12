{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    ./home-manager
    ./locale.nix
    ./nix.nix
    ./sand.berg-certificates.nix
    ./systempackages.nix

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

  # SSH server
  services.openssh.enable = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
