{
  lib,
  pkgs,
  config,
  ...
}: {
  systemd.user.services.waybar = {
    Unit = {
      # BindsTo = [ "tray.target" ];
      After = lib.mkForce ["graphical-session.target"];
      Requisite = ["graphical-session.target"];
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
      height = 30;
      margin-top = 0;
      margin-left = 0;
      margin-right = 0;
      #spacing = 4;
      modules-left = ["niri/workspaces" "network" "cpu" "memory" "battery" "backlight/slider"];
      modules-center = ["clock"];
      modules-right = ["wlr/taskbar" "tray" "pulseaudio"];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "";
          inactive = "";
          default = "";
          urgent = "";
        };
      };

      "wlr/taskbar" = {
        format = "{icon}";
        tooltip-format = "{title} | {app_id}";
        on-click = "activate";
        on-click-middle = "close";
        on-click-right = "fullscreen";
        rewrite = {
          # Truncate any format over 16 characters.
          "^(.{16}).+$" = "$1…";
        };
      };

      "backlight/slider" = {
        min = 5;
        max = 100;
        orientation = "horizontal";
        device = "intel_backlight";
      };
      /*
      "custom/exit" = {
        tooltip = false;
        format = "";
        on-click = "sleep 0.1 && wlogout";
      };
      */
      "tray" = {
        icon-size = 14;
        spacing = 1;
      };

      "clock" = {
        format = "{:%H:%M}";
        format-alt = "{:%Y-%m-%d}";
        tooltip = true;
        tooltip-format = "{:%Y-%m-%d}";
        #tooltip-format = "{calendar}";
      };

      "cpu".format = " {usage}% ";

      "memory".format = " {}%";

      "battery" = {
        states = {
          warning = 30;
          critical = 1;
        };
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-alt = "{time} {icon}";
        format-icons = ["" "" "" "" ""];
      };

      "network" = {
        #format-wifi = "  {essid} ({signalStrength}%)";
        format-wifi = " {signalStrength}%";
        format-ethernet = "  {ifname}: {ipaddr}/{cidr}";
        format-disconnected = "⚠ Disconnected";
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

    #style = builtins.readFile ./waybar-style.css;
    style = ''
      @define-color bg ${config.lib.stylix.colors.withHashtag.base01};
      @define-color bg2 ${config.lib.stylix.colors.withHashtag.base02};
      @define-color fg ${config.lib.stylix.colors.withHashtag.base04};
      @define-color highlight ${config.lib.stylix.colors.withHashtag.base09};

      * {
          border: none;
          border-radius: 0px;
          font-family: "monospace";
          font-size: 12px;
          font-weight: bold;
          min-height: 0;
          margin-left: 4px;
          margin-right: 4px;
          padding: 2px 5px;
      }

      window#waybar {
          background: transparent;
      }

      tooltip {
          background: @bg2;
          border-radius: 0px;
          border: 1px solid @highlight;
          font-weight: normal;
      }

      #window,
      #clock,
      #battery,
      #pulseaudio,
      #network,
      #tray,
      #backlight-slider,
      #taskbar,
      #cpu,
      #memory
      {
          background: @bg;
          border-radius: 10px;
          padding: 0px 10px;
          margin: 7px 5px 0px 5px;
          transition: all 0.2s ease-in-out;
      }

      #pulseaudio,
      #battery,
      #backlight-slider
      {
          color: @fg;
      }

      #clock:hover,
      #battery:hover,
      #pulseaudio:hover,
      #tray:hover,
      #custom-power:hover,
      #workspaces button:hover,
      #cpu:hover,
      #memory:hover,
      #network:hover
      {
          background: @fg;
          color: @bg;
      }

      #workspaces {
          background: @bg;
          padding: 0px 5px 0px 5px;
          border-radius: 10px;
          margin: 7px 5px 0px 5px;
      }

      #workspaces button {
          background: transparent;
          border-radius: 20px;
      }

      #workspaces button.active {
          background: @fg;
          color: @bg;
      }

      #workspaces button.visible,
      #workspaces button.empty
      {
          color: @bg2;
      }


      #taskbar button.active {
          background: transparent;
          border-bottom: 3px solid @fg;
      }

      #backlight-slider
      {
          background: @bg;
          border-radius: 10px;
          padding: 0px;
          margin: 7px 5px 0px 5px;
      }

      #backlight-slider slider {
          min-height: 0px;
          min-width: 0px;
          opacity: 0;
          background-image: none;
          border: none;
          box-shadow: none;
          background-color: transparent;
      }
      #backlight-slider trough {
          min-height: 10px;
          min-width: 100px;
          border-radius: 0px;
          background-color: transparent;
      }
      #backlight-slider highlight {
          min-width: 1px;
          border-radius: 5px;
          background-color: @fg;
      }

    '';
  };
}
