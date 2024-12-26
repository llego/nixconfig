{username, ...}: {
  home-manager.users.${username} = {
    imports = [
      ./swayidle.nix
    ];

    # niri msg outputs
    programs.niri.settings.outputs.HDMI-A-1 = {
      enable = true;
      scale = 1.6;
      mode = {
        width = 3840; #5120;
        height = 2160;
        refresh = 59.997;
      };
      variable-refresh-rate = true;
    };

    home.stateVersion = "24.11";
  };

  services.swayidle = {
    enable = true;
    systemdTarget = "graphical-session.target";
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
      {
        timeout = 600;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      /*
        {
        timeout = 1200;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
      */
    ];
  };
}
