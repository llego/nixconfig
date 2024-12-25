{pkgs, ...}: {
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "shutdown";
        action = "sleep 1; systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        "label" = "reboot";
        "action" = "sleep 1; systemctl reboot";
        "text" = "Reboot";
        "keybind" = "r";
      }
      {
        "label" = "logout";
        "action" = "sleep 1; niri msg action quit -s";
        "text" = "Exit";
        "keybind" = "e";
      }
      {
        "label" = "suspend";
        "action" = "sleep 1; systemctl suspend";
        "text" = "Suspend";
        "keybind" = "u";
      }
      {
        "label" = "lock";
        "action" = "sleep 1; ${pkgs.swaylock}/bin/swaylock -f";
        "text" = "Lock";
        "keybind" = "l";
      }
      {
        "label" = "monitor-off";
        "action" = "sleep 1; ${pkgs.niri}/bin/niri msg action power-off-monitors";
        "text" = "Monitor off";
        "keybind" = "m";
      }
      /*
      {
        "label" = "hibernate";
        "action" = "sleep 1; systemctl hibernate";
        "text" = "Hibernate";
        "keybind" = "h";
      }
      */
    ];
  };
}
