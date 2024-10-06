{ pkgs, lib, inputs, ... }: {
  
  # Instead of requiring you to build Hyprland (and its dependencies, which may include mesa, ffmpeg, etc), we provide a Cachix cache that you can add to your Nix configuration.
  # In order for Nix to take advantage of the cache, it has to be enabled before using the Hyprland flake package.
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };
  
  programs.hyprland = {
    enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

}
