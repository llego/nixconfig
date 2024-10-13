{ inputs, ... }:

{
  imports = [
    ./common.nix
    ./home-manager/default-niri.nix
    inputs.niri.nixosModules.niri
  ];

  niri-flake.cache.enable = true;
  programs.niri.enable = true;
  environment.variables.NIXOS_OZONE_WL = "1";

  #programs.waybar.enable = true;

}
