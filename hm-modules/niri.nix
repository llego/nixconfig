{ config, pkgs, inputs, username, ... }:
  
  # enable the binary cache niri.cachix.org in your nix configuration
  niri-flake.cache.enable = true;

  programs.niri.enable = true;


}
