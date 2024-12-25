{username, ...}: {
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    imports = [./kanshi.nix];
  };
}
