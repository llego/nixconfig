{
  services.kanshi = {
    enable = true;
    #systemdTarget = "niri.service";
    systemdTarget = "graphical-session.target";

    settings = [
      {
        profile.name = "home_office";
        profile.outputs = [
          {
            criteria = "DP-1";
            status = "enable";
            mode = "3840x2160";
            scale = 1.6;
          }
        ];
      }
    ];
  };
}
