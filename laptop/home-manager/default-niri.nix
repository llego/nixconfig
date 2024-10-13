{ inputs, username, ... }:
{
  imports = [ ./common.nix ];
  home-manager.users.${username}.imports = [ ./user/default-niri.nix ]; 
}
