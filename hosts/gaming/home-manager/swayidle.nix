{pkgs, ...}: {
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
