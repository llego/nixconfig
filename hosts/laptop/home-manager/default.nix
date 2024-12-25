{username, ...}: {
  home-manager.users.${username} = {
    home.stateVersion = "24.05";
    imports = [./kanshi.nix];
  };
}
