{ pkgs, ... }:

{

  imports = [ 
    ./common.nix
    ./niri.nix
    ./waybar.nix
    ./kanshi.nix
    ./xwayland-satellite.nix
  ];
  
  gtk.iconTheme = {
    package = pkgs.kdePackages.breeze-icons;
    name = "breeze";
  };
  
}
