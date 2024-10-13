{ pkgs, ... }:
{
  # Needs to be set from niri, otherwise niri will delete it when booting
  # https://github.com/YaLTeR/niri/blob/2983eb31135b9eda269fd7fc1157a66607448b70/src/main.rs#L71
  programs.niri.settings.environment = {
    DISPLAY = ":0";
  };

  systemd.user.services.xwayland-satellite = {
    Unit = {
      After = [ "niri.service" ];
      Requires = [ "niri.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
      Restart = "on-failure";
    };
  };
}
