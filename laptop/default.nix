{ pkgs, inputs, username, hostname, ... }:

{
  imports = [ 
    ./../hardware-configuration/laptop.nix
    ./home-manager
    ./stylix
    ./hardware.nix
    ./locale.nix
    ./nix.nix
    ./sand.berg-certificates.nix
    ./systempackages.nix
    ./wifi-networks.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
  ];
  
  # Minimum home-manager user config for laptop
  home-manager.users.${username}.imports = [ 
    ./home-manager/user
    ./home-manager/user/desktop-apps.nix
    ./home-manager/user/desktopEntries.nix
    ./home-manager/user/gtk.nix
  ];

  networking.hostName = "${hostname}";
  
  users.users.${username} = {
    isNormalUser = true;
    initialPassword = "12345";
	  description = "Christian Sandberg";
	  extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  
	# Allow passwordless sudo for llego
	security.sudo.extraRules = [
	  {
	    users = [ "${username}" ];
	    commands = [
	      {
	        command = "ALL";
	        options = [ "SETENV" "NOPASSWD" ];
	      }
	    ];
	  }
	];
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  #boot.plymouth.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";

}

