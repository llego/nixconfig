{username, ...}: {
  home-manager.users.${username} = {
    home.stateVersion = "24.05";
    imports = [
      ./kanshi.nix
      ./swayidle.nix
    ];

    home.packages = with pkgs; [mqtt-explorer];
  };
}
