{username, ...}: {
  home.sessionVariables = {
    EDITOR = "gnome-text-editor";
    FLAKE = "/home/${username}/nixconfig"; # Needed by nh to work from any dir
    TERMINAL = "kitty";
  };
}
