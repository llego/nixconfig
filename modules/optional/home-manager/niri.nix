{
  config,
  pkgs,
  ...
}: {
  programs.swaylock = {
    enable = true;
    settings = {
      font-size = 24;
      indicator-idle-visible = true;
      indicator-radius = 100;
      show-failed-attempts = true;
    };
  };

  home.packages = [
    pkgs.brightnessctl
    pkgs.libnotify
    pkgs.swaybg
  ];

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = ["graphical-session-pre.target"];
      After = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  systemd.user.services = {
    swaybg = {
      Install = {
        WantedBy = ["graphical-session.target"];
      };
      Unit = {
        Description = "swaybg service for background";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
        Requisite = "graphical-session.target";
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill";
        Restart = "on-failure";
      };
    };
  };

  services = {
    mako = {
      enable = true;
      settings = {
        defaultTimeout = 10000;
        borderRadius = 4;
        borderSize = 1;
      };
    };
    network-manager-applet.enable = true;
  };

  programs.niri.settings = {
    cursor.theme = "default";
    cursor.size = 24;
    input = {
      keyboard.xkb.layout = "fi";
      #focus-follows-mouse.enable = true;
      #warp-mouse-to-focus = false;
    };

    spawn-at-startup = [
      {command = ["exec" "sleep" "3;" "systemctl" "--user" "reset-failed" "waybar.service"];}
      #{ command = ["systemctl" "--user" "restart" "waybar.service"]; }
      {command = ["systemctl" "--user" "restart" "network-manager-applet.service"];}
      {command = ["systemctl" "--user" "restart" "swayidle.service"];}
    ];

    layout = {
      always-center-single-column = true;
      struts.top = -8.0;
      border.active.gradient = {
        from = "${config.lib.stylix.colors.withHashtag.base09}";
        to = "${config.lib.stylix.colors.withHashtag.base0B}";
        angle = 45;
      };
      shadow.enable = true;
    };

    layer-rules = [
      {
        matches = [{namespace = "^wallpaper$";}];
        #place-within-backdrop = true;
      }
    ];

    window-rules = [
      {
        geometry-corner-radius = {
          bottom-left = 4.0;
          bottom-right = 4.0;
          top-left = 4.0;
          top-right = 4.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [{app-id = "^org[.]pulseaudio[.]pavucontrol$";}];
        default-column-width.fixed = 762;
      }
      # Make non-active windows semi-transparent
      {
        matches = [{is-active = false;}];
        opacity = 0.9;
        draw-border-with-background = false;
      }
      {
        matches = [{app-id = "gamescope";}];
        open-fullscreen = true;
      }
    ];

    # ask the applications to omit their client-side decorations.
    prefer-no-csd = true;

    # skip hotkey overlay
    hotkey-overlay.skip-at-startup = true;

    binds = with config.lib.niri.actions; let
      sh = spawn "sh" "-c";
    in {
      "Mod+Shift+7".action = show-hotkey-overlay;

      "Mod+L".action.spawn = "swaylock";
      "Alt+Return".action.spawn = "alacritty";
      "Alt+Space".action.spawn = "fuzzel";
      "Alt+W".action.spawn = "firefox";
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

      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
      "Mod+V".action = toggle-window-floating;

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

      "Print".action = screenshot;
      #"Ctrl+Print".action = screenshot-screen;
      #"Alt+Print".action = screenshot-window;

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

      "XF86MonBrightnessDown".action.spawn = ["${pkgs.brightnessctl}/bin/brightnessctl" "set" "5%-"];
      "XF86MonBrightnessUp".action.spawn = ["${pkgs.brightnessctl}/bin/brightnessctl" "set" "5%+"];

      "Mod+Shift+W".action = sh (builtins.concatStringsSep "; " [
        "systemctl --user restart waybar.service"
      ]);
    };
  };
}
