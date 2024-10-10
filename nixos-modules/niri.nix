{ config, pkgs, inputs, username, ... }:
{  
  # enable the binary cache niri.cachix.org in your nix configuration
  #niri-flake.cache.enable = true;
  nix.settings = {
    substituters = ["https://niri.cachix.org"];
    trusted-public-keys = ["niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="];
  };

  #programs.niri.package = pkgs.niri;


  programs.niri.enable = true;


}
