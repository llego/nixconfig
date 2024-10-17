{ inputs, pkgs, username, ...}:
{
  imports = [ ./xserver.nix ];
  
  desktopManager.gnome.enable = true;

  home-manager.users.${username}.imports = [ 
    ./home-manager/user/gnome.nix
  ]; 
  
}
