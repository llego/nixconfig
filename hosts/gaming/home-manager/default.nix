{username, ...}: {
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    imports = [
      ./niri-config.nix
      ./swayidle.nix
    ];
  };
}
