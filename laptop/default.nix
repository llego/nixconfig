{ pkgs, inputs, username, hostname, ... }:

{
  imports = [ 
    ./../hardware-configuration/laptop.nix
    ./home-manager
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
  
  # Default home-manager user config for laptop
  home-manager.users.${username}.imports = [ 
    ./home-manager/user
    ./home-manager/user/desktop-apps.nix
    ./home-manager/user/gtk.nix
  ];
  
  specialisation = {
    gnome.configuration = {
      environment.etc."specialisation".text = "gnome";
      
      services.xserver.desktopManager.gnome.enable = true;
      
      home-manager.users.${username}.imports = [ 
        ./home-manager/user/gnome.nix
      ]; 
    };
    
    niri.configuration = {
      environment.etc."specialisation".text = "niri";
      
      imports = [ inputs.niri.nixosModules.niri ];
      
      home-manager.users.${username}.imports = [ 
        ./home-manager/user/fuzzel.nix
        ./home-manager/user/kanshi.nix
        ./home-manager/user/niri.nix
        ./home-manager/user/waybar.nix
        ./home-manager/user/wlogout.nix
        ./home-manager/user/xwayland-satellite.nix
      ]; 
      
      niri-flake.cache.enable = true;
      programs.niri.enable = true;
      services.blueman.enable = true;   # Bluetooth
      services.gvfs.enable = true;      # Nautilus sftp
      environment.variables.NIXOS_OZONE_WL = "1";
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

