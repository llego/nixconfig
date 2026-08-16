{
  pkgs,
  username,
  dots,
  inputs,
  ...
}: {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  programs.noctalia-greeter = {
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

        bar.default = {
          background_opacity = 0.8;
          center = [];
          end = ["cpu" "ram" "brightness" "volume" "battery" "network" "clock"];
          font_family = "Inter Variable";
          margin_edge = 8;
          margin_ends = 15;
          start = ["workspaces" "active_window"];
          widget_spacing = 12;
        };

        shell = {
          niri_overview_type_to_launch_enabled = true;
          polkit_agent = true;
        };

        theme = {
          builtin = "Rosé Pine";
          community_palette = "Oxocarbon";
          mode = "dark";
          source = "wallpaper";
          wallpaper_scheme = "m3-rainbow";
        };

        wallpaper = {
          directory = "${dots}/noctalia/wallpapers";
          transition = ["wipe"];
          transition_on_startup = true;
        };

        widget = {
          active_window.max_length = 566;
          battery = {
            type = "battery";
            capsule = false;
            display_mode = "graphic";
            show_label = false;
          };
          brightness.capsule = false;
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
          volume.capsule = false;
        };
      };
    };
  };
}
