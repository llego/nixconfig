{ lib, pkgs,  ... }:
{ 

  systemd.user.services.waybar = {
    Unit = {
      # BindsTo = [ "tray.target" ];
      After = lib.mkForce [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPost = "${pkgs.coreutils}/bin/sleep 2";
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "tray.target";
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      margin-top = 4;
      margin-left = 4;
      margin-right = 4;
      spacing = 5;
      modules-left = [ "niri/workspaces" "wlr/taskbar" ];
      #modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" "clock" "custom/exit" ];
      
      # removed "custom/notification" from modules-right
      
      "niri/workspaces" = {
        format = "{icon}";
        active = "";
  		  default = "";
      };

      "wlr/taskbar" = {
        #format = "{icon}";
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
      
      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='red'><sup></sup></span>";
          none = "";
          dnd-notification = "<span foreground='red'><sup></sup></span>";
          dnd-none = "";
          inhibited-notification = "<span foreground='red'><sup></sup></span>";
          inhibited-none = "";
          dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };
        
     "custom/exit" = {
        tooltip = false;
        format = " ";
        on-click = "sleep 0.1 && wlogout";
      };

      "tray".spacing = 15;
      "clock".format-alt = "{:%Y-%m-%d}";
      "cpu".format = " {usage}% ";
      "memory".format = " {}%";
      "battery" = {
        bat = "BAT0";
        format = "{icon} {capacity}%";
        format-icons = ["" "" "" "" ""];
        format-plugged = "{capacity}% ";
      };
      "network" = {
        #format-wifi = "  {essid} ({signalStrength}%)";
        format-wifi = " {signalStrength}%";
        format-ethernet = "  {ifname}: {ipaddr}/{cidr}";
        format-disconnected =  "⚠ Disconnected";
        format-alt = "{ifname}: {ipaddr}/{cidr}";
        #on-click = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      };
      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-bluetooth = "{icon}  {volume}%";
        format-muted = " ";
        format-icons = {
            headphones = " ";
            default = ["" ""];
        };
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
    };

    style = builtins.readFile ../assets/waybar-style.css;

  };

}
