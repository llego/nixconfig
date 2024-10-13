# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, username, host, ... }:

{
  imports = [ 
    ./hardware.nix
    ./locale.nix
    ./niri.nix
    ./nix.nix
    ./sand.berg-certificates.nix
    ./systempackages.nix
    ./wifi-networks.nix
    ./xserver.nix

    ./home-manager/default-niri.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.niri.nixosModules.niri
    
    ./stylix
    inputs.stylix.nixosModules.stylix
  ];
  
  #networking.hostName = "${host}";
  
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

