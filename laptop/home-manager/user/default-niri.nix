{ pkgs, inputs, username, ... }:

{
  # Let Home Manager install and manage itself
  # programs.home-manager.enable = true;

  imports =[ 
    ./bandcamp-collection.nix
    ./cli.nix
    ./desktop-apps.nix
    ./lf.nix
    ./zsh.nix
    ./niri.nix
    ./waybar.nix
    ./kanshi.nix
    ./xwayland-satellite.nix
  ];
  
  gtk.iconTheme = {
    package = pkgs.kdePackages.breeze-icons;
    name = "breeze";
  };
    
  home.sessionVariables = {
  	  EDITOR = "vim";
  	  FLAKE = "/home/${username}/nixconfig";  # Needed by nh to work from any dir
  };
  
#  fonts.fontconfig.enable = true;
  
  home.stateVersion = "24.05";
  
}
