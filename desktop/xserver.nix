{config, pkgs, ...}:
{
  # Enable the X11 windowing system, GNOME Desktop Environment, and configure keymap
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "se";
      variant = "";
    };
  };
}
