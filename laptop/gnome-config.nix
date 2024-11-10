{username, ...}: {
  # Enable the X11 windowing system, GNOME Desktop Environment, and configure keymap
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    #displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "fi";
      variant = "";
    };
  };

  home-manager.users.${username}.imports = [
    ./home-manager/user/gnome.nix
  ];
}
