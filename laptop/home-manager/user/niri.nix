{ config, lib, pkgs,  ... }:
{

  programs.swaylock.enable = true;

  home.packages = [ 
    pkgs.brightnessctl
    pkgs.libnotify
    pkgs.swaybg
  ];
  
  services = {
    swaync = {
      enable = true;
      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        control-center-layer = "top";
        layer-shell = true;
        cssPriority = "application";
        control-center-margin-top = 0;
        control-center-margin-bottom = 0;
        control-center-margin-right = 0;
        control-center-margin-left = 0;
        notification-2fa-action = true;
        notification-inline-replies = false;
        notification-icon-size = 64;
        notification-body-image-height = 100;
        notification-body-image-width = 200;
      };
    };
    #mako.enable = true;
    network-manager-applet.enable = true;
    swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
      ];
      timeouts = [
        {
          timeout = 120;
          command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        }
        {
          timeout = 600;
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
        {
          timeout = 1200;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };
  
  programs.niri.settings = {
    #outputs."DP-2".scale = 2;
    #outputs."eDP-1".scale = 1.6;
    #outputs."eDP-1".enable = true;

    input = {
      keyboard.xkb.layout = "fi";
      focus-follows-mouse.enable = true;
      warp-mouse-to-focus = false;
    };

    spawn-at-startup = [
        { command = ["${lib.getExe pkgs.waybar}"]; }
        #{ command = ["${pkgs.waybar}/bin/waybar"]; }
        #{ command = ["systemctl" "--user" "restart" "waybar.service"]; }
        #{ command = ["systemctl" "--user" "restart" "kanshi.service"]; }
        { command = ["${pkgs.networkmanagerapplet}/bin/nm-applet" "--indicator"]; }
        { command = ["${pkgs.swaybg}/bin/swaybg" "-i" "${config.stylix.image}" "-m" "fill"]; }
        #"exec sleep 5; systemctl --user reset-failed waybar.service" 
        #{ command = ["systemctl" "--user" "restart" "waybar.service"]; }
        #"exec sleep 3; systemctl --user start waybar.service"
        #"exec sleep 5; ${pkgs.waybar}/bin/waybar -c ${config.home.homeDirectory}/.config/waybar/config"
        #"exec sleep 5; systemctl --user start kanshi.service"
        #"exec sleep 3; systemctl --user start network-manager-applet.service"
      #]; }
    ];
    
    window-rules = [
      {
        geometry-corner-radius = {
          bottom-left = 12.0;
          bottom-right = 12.0;
          top-left = 12.0;
          top-right = 12.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [ { app-id = "^org[.]pulseaudio[.]pavucontrol$"; } ];
        default-column-width.fixed = 762;
      }
      {
        matches = [ { app-id = "kitty"; } ];
        opacity = 0.90;
        draw-border-with-background = false;
      }
    ];
    
    #window-rules."active-window" = {
      #matches.is-active = true;
      #geometry-corner-radius = 8;
    #};
    
    # ask the applications to omit their client-side decorations.
    prefer-no-csd = true;

    binds = with config.lib.niri.actions; let
      sh = spawn "sh" "-c";
    in {
      "Mod+Shift+7".action = show-hotkey-overlay;
      
      "Mod+L".action.spawn = "swaylock";
      "Alt+Return".action.spawn = "kitty";
      "Alt+Space".action.spawn = "fuzzel";
      "Alt+W".action.spawn = "chromium";
      "Alt+F".action.spawn = "nautilus";
      "Alt+T".action.spawn = "gnome-text-editor";

      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Up".action = focus-window-or-workspace-up;
      "Mod+Down".action = focus-window-or-workspace-down;

      "Mod+Ctrl+Left".action = move-column-left;
      "Mod+Ctrl+Right".action = move-column-right;
      "Mod+Ctrl+Up".action = move-window-up-or-to-workspace-up;
      "Mod+Ctrl+Down".action = move-window-down-or-to-workspace-down;

      "Mod+Page_Down".action = focus-window-or-workspace-down;
      "Mod+Page_Up".action = focus-window-or-workspace-up;
      "Mod+U".action = focus-workspace-down;
      "Mod+I".action = focus-workspace-up;

      "Mod+Q".action = close-window;
      
      "Mod+Comma".action = consume-window-into-column;
      "Mod+Period".action = expel-window-from-column;


      "Mod+Shift+P".action = power-off-monitors;
      "Mod+P".action.spawn = "${pkgs.kanshi}/bin/kanshi -c ${config.home.homeDirectory}/.config/kanshi/config";
      "Mod+Shift+E".action = quit;
      "Ctrl+Alt+Delete".action.spawn = "${pkgs.wlogout}/bin/wlogout";

      "Mod+Plus".action = set-column-width "+10%";
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = fullscreen-window;
      
      Print.action = screenshot;
      "Ctrl+Print".action = screenshot-screen;
      "Alt+Print".action = screenshot-window;
      
      XF86AudioRaiseVolume = {
        action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+";
        allow-when-locked = true;
      };
      XF86AudioLowerVolume = {
        action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-";
        allow-when-locked = true;
      };
      XF86AudioMute = {
        action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
        allow-when-locked = true;
      };
      XF86AudioMicMute = {
        action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
        allow-when-locked = true;
      };

      "XF86MonBrightnessDown".action.spawn = [ "${pkgs.brightnessctl}/bin/brightnessctl" "set" "10%-"];
      "XF86MonBrightnessUp".action.spawn = [ "${pkgs.brightnessctl}/bin/brightnessctl" "set" "10%+"];

    #  "Mod+Shift+W".action = sh (builtins.concatStringsSep "; " [
    #    "systemctl --user restart waybar.service"
    #  ]);
    };

  };


}
