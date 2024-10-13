# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, username, hostname, ... }:

{
  imports = [ 
    ./../hardware-configuration/laptop.nix
    ./hardware.nix
    ./locale.nix
    ./nix.nix
    ./sand.berg-certificates.nix
    ./systempackages.nix
    ./stylix
    ./wifi-networks.nix
    ./xserver.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
  ];
  
  specialisation = {
    gnome.configuration = {
      environment.etc."specialisation".text = "gnome";
      imports = [ ./home-manager/default-gnome.nix ];
    };
    
    niri.configuration = {
      environment.etc."specialisation".text = "niri";
      imports = [ ./home-manager/default-niri.nix inputs.niri.nixosModules.niri ];

      niri-flake.cache.enable = true;
      programs.niri.enable = true;
      environment.variables.NIXOS_OZONE_WL = "1";
      #programs.waybar.enable = true;
    };
  };
  
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";

}

