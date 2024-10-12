{ config, pkgs, inputs, username, ... }:

{
  # Let Home Manager install and manage itself
  # programs.home-manager.enable = true;

  imports =
    [ 
      ./bandcamp-collection.nix
      ./cli.nix
      ./desktop-apps.nix
      ./gnome.nix
      ./lf.nix
      #./niri.nix
      ./zsh.nix
    ];
    
  #home.username = "${username}";
	#home.homeDirectory = "/home/${username}";
  home.sessionVariables = {
  	  EDITOR = "vim";
  	  FLAKE = "/home/${username}/nixconfig";  # Needed by nh to work from any dir
  };
  
#  fonts.fontconfig.enable = true;
  
  home.stateVersion = "24.05";
  
  
}
