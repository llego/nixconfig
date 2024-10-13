{ pkgs,  ... }:
{ 
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      margin-top = 4;
      margin-left = 4;
      margin-right = 4;
      spacing = 0;
      modules-left = [ "niri/workspaces" "wlr/taskbar" ];
      modules-center = [ "clock" ];
      modules-right = ["pulseaudio" "network" "cpu" "memory" "battery" "tray"];

      "niri/workspaces" = {
        format = "{icon}";
        active = "";
  		  default = "";
      };

      "wlr/taskbar" = {
        format = "{icon} {title}";
        tooltip-format = "{title} | {app_id}";
        on-click = "activate";
        on-click-middle = "close";
        on-click-right = "fullscreen";
        rewrite = {
          # Truncate any format over 16 characters.
          "^(.{16}).+$" = "$1…";
        };
      };

      "tray".spacing = 10;
      "clock".format-alt = "{:%Y-%m-%d}";
      "cpu".format = "{usage}% ";
      "memory".format = "{}% ";
      "battery" = {
        bat = "BAT0";
        format = "{capacity}% {icon}";
        format-icons = ["" "" "" "" ""];
        format-plugged = "{capacity}% ";
      };
      "network" = {
        format-wifi = "{essid} ({signalStrength}%) ";
        format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
        format-disconnected =  "Disconnected ⚠";
        format-alt = "{ifname}: {ipaddr}/{cidr}";
        on-click = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      };
      "pulseaudio" = {
        format = "{volume}% {icon}";
        format-bluetooth = "{volume}% {icon}";
        format-muted = "";
        format-icons = {
            headphones = "";
            default = ["" ""];
        };
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
    };

    style = builtins.readFile ../assets/waybar-style.css;

  };

}
