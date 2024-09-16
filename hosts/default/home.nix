{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  imports =
    [ 
      ../../hm-modules/desktop-apps.nix
      ../../hm-modules/zsh.nix
      ../../hm-modules/cli-utils.nix
      ../../hm-modules/chromium.nix
      ../../hm-modules/gnome.nix
      ../../hm-modules/lf.nix
      #../../shellscripts/bandcamp/shellscripts.nix
    ];
    
  home.username = "llego";
	home.homeDirectory = "/home/llego";
  home.sessionVariables = {
  	EDITOR = "nano";
  };
  
  fonts.fontconfig.enable = true;
  
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
