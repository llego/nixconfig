{ config, pkgs, inputs, username, ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  imports =
    [ 
      ../../hm-modules/cli.nix
      ../../hm-modules/desktop-apps.nix
      ../../hm-modules/zsh.nix
      ../../hm-modules/gnome.nix
      #../../hm-modules/hyprland.nix
      ../../hm-modules/bandcamp-collection.nix
    ];
    
  home.username = "${username}";
	home.homeDirectory = "/home/${username}";
  home.sessionVariables = {
  	  EDITOR = "nano";
  	  FLAKE = "/home/${username}/nixconfig";  # Needed by nh to work from any dir
  };
  
#  fonts.fontconfig.enable = true;
  
  home.stateVersion = "24.05";
  
  home.file = {
       # # Building this configuration will create a copy of 'dotfiles/screenrc' in
       # # the Nix store. Activating the configuration will then make '~/.screenrc' a
       # # symlink to the Nix store copy.
       # ".screenrc".source = dotfiles/screenrc;

       # # You can also set the file content immediately.
       # ".gradle/gradle.properties".text = ''
       #   org.gradle.console=verbose
       #   org.gradle.daemon.idletimeout=3600000
       # '';
  };
  
}
