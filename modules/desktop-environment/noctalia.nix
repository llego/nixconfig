{
  pkgs,
  username,
  inputs,
  ...
}: {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "Niri";
      user.default = username;
      cursor = {
        theme = "Numix-Cursor";
        size = 24;
        path = "${pkgs.numix-cursor-theme}/share/icons";
      };
      keyboard.layout = "fi";
      idle.timeout = 300;
    };
  };

  hjem.users.${username} = {
    imports = [
      inputs.noctalia.hjemModules.default
    ];
    programs.noctalia = {
      enable = true;
      settings = {
        backdrop.enabled = false;

        bar = {
          default = {
            start = [
              "taskbar"
            ];
            center = [
              "active_window"
            ];
            end = [
              "cpu"
              "ram"
              "brightness"
              "volume"
              "battery"
              "network"
              "bar"
              "clock"
            ];
            background_opacity = 0.7;
            margin_edge = 8;
            margin_ends = 15;
            shadow = false;
            widget_spacing = 12;
          };
        };

        widget = {
          active_window.max_length = 566;
          battery = {
            type = "battery";
            display_mode = "graphic";
            show_label = false;
          };
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            visualization = "graph";
          };
          ram = {
            type = "sysmon";
            stat = "ram_pct";
            visualization = "graph";
          };
          network.show_label = false;
          taskbar = {
            group_by_workspace = true;
            hide_empty_workspaces = true;
            show_workspace_label = false;
          };
          bar = {
            show_count = false;
            type = "rylos/tailnet:bar";
          };
        };

        plugins.enabled = ["rylos/tailnet"];

        idle = {
          behavior = {
            lock = {
              action = "lock";
              enabled = true;
              timeout = 600.0;
            };
            lock-and-suspend = {
              action = "lock_and_suspend";
              enabled = true;
              timeout = 900.0;
            };
            screen-off = {
              action = "screen_off";
              enabled = true;
              timeout = 600.0;
            };
          };
          behavior_order = [
            "screen-off"
            "lock"
            "lock-and-suspend"
          ];
        };

        shell = {
          niri_overview_type_to_launch_enabled = true;
          polkit_agent = true;
        };

        theme = {
          mode = "dark";
          templates = {
            builtin_ids = [
              "btop"
              "gtk3"
              "niri"
            ];
            community_ids = [
              "fuzzel"
              "bat"
              "lazygit"
            ];
          };
        };

        wallpaper = {
          directory = "/mnt/crisuflix-wallpapers";
          transition = ["wipe"];
          transition_on_startup = true;
        };
      };
    };
  };
}
