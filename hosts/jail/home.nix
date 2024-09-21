{ config, pkgs, inputs, ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  imports =
    [ 
      ../../hm-modules/zsh.nix
      ../../hm-modules/cli-utils.nix
      ../../hm-modules/lf.nix
    ];
    
  home.username = "llego";
	home.homeDirectory = "/home/llego";
  home.sessionVariables = {
  	EDITOR = "nano";
  };
  
  fonts.fontconfig.enable = true;
  
  home.stateVersion = "24.05";
    
  # Enable Flakes
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
    
}
