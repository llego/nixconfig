{ config, pkgs, inputs, username, ... }:
{  
  programs.niri.settings = {
    #outputs."DP-2".scale = 2;
    #outputs."eDP-1".scale = 1.6;
    #outputs."eDP-1".enable = true;

    input.keyboard.xkb.layout = "fi";

    spawn-at-startup = [
      { command = [ 
        "exec sleep 5; systemctl --user reset-failed waybar.service" 
        #"exec sleep 3; systemctl --user start waybar.service"
        #"exec sleep 5; ${pkgs.waybar}/bin/waybar -c ${config.home.homeDirectory}/.config/waybar/config"
        "exec sleep 5; systemctl --user start hyprpaper.service"
        "exec sleep 5; systemctl --user start kanshi.service"
        "exec sleep 7; ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"
        #"exec sleep 3; systemctl --user start network-manager-applet.service"
      ]; }
    ];

    #window-rules."active-window" = {
      #matches.is-active = true;
      #geometry-corner-radius = 8;
    #};

    binds = with config.lib.niri.actions; let
      sh = spawn "sh" "-c";
    in {
      "Mod+Shift+7".action = show-hotkey-overlay;

      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Up".action = focus-window-up;
      "Mod+Down".action = focus-window-down;

      "Mod+Ctrl+Left".action = move-column-left;
      "Mod+Ctrl+Right".action = move-column-right;
      "Mod+Ctrl+Up".action = move-window-up;
      "Mod+Ctrl+Down".action = move-window-down;

      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+U".action = focus-workspace-down;
      "Mod+I".action = focus-workspace-up;

      "Mod+Q".action = close-window;
      "Super+Alt+L".action.spawn = "swaylock";
      "Mod+T".action.spawn = "${pkgs.kitty}/bin/kitty";
      "Alt+Return".action.spawn = "${pkgs.kitty}/bin/kitty";
      "Mod+D".action.spawn = "${pkgs.fuzzel}/bin/fuzzel";
      "Mod+Return".action.spawn = "${pkgs.fuzzel}/bin/fuzzel";
      "Alt+W".action.spawn = "${pkgs.chromium}/bin/chromium";

      "Mod+Shift+P".action = power-off-monitors;
      "Mod+P".action.spawn = "${pkgs.kanshi}/bin/kanshi -c ${config.home.homeDirectory}/.config/kanshi/config";
      "Mod+Shift+E".action = quit;

      "Mod+Plus".action = set-column-width "+10%";
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = fullscreen-window;

      "XF86AudioRaiseVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"];
      "XF86AudioLowerVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"];

      # Not working
      "XF86MonBrightnessDown".action.spawn = ["light" "-A" "10"];
      "XF86MonBrightnessUp".action.spawn = ["light" "-U" "10"];

      "Mod+Shift+W".action = sh (builtins.concatStringsSep "; " [
        "systemctl --user restart waybar.service"
        "systemctl --user restart hyprpaper.service"
      ]);
    };

  };

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

  programs.fuzzel = {
    enable = true;
  };

  services.network-manager-applet.enable = true;

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "off";
      splash = true;
      preload = [ "../assets/wallpaper-blue.jpg" ];
      wallpaper = [ 
        "eDP-1, ./assets/wallpaper-blue.jpg"
        "DP-2, ../assets/wallpaper-blue.jpg" 
      ];
    };
  };

  services.kanshi = {
    enable = true;
    systemdTarget = "niri.service";

    settings = [
      { profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            scale = 1.6;
            status = "enable";
          }
        ];
      }
      { profile.name = "home_office_1";
        profile.outputs = [
          {
            criteria = "DP-1";
            status = "enable";
          }
          {
            criteria = "eDP-1";
            scale = 1.0;
            status = "disable";
          }
        ];
      }
      { profile.name = "home_office_2";
        profile.outputs = [
          {
            criteria = "DP-2";
            status = "enable";
          }
          {
            criteria = "eDP-1";
            scale = 1.0;
            status = "disable";
          }
        ];
      }
    ];
  };

}
