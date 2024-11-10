{
  services.kanshi = {
    enable = true;
    #systemdTarget = "niri.service";
    systemdTarget = "graphical-session.target";

    settings = [
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            scale = 2.0;
          }
        ];
      }
      {
        profile.name = "home_office_1";
        profile.outputs = [
          {
            criteria = "DP-1";
            status = "enable";
            #mode = "5120x2160@30Hz"; # not working
            #mode = "4320x1800"; # not quite working. laptop monitor stays on. has black bars on the sides
            #mode = "2560x1080"; # working, no black bars, but everything is too big
            mode = "3840x2160"; # workin, but has black bars on the sides
            scale = 1.6;
          }
          {
            criteria = "eDP-1";
            status = "disable";
            scale = 2.0;
          }
        ];
      }
      {
        profile.name = "home_office_2";
        profile.outputs = [
          {
            criteria = "DP-2";
            status = "enable";
            #mode = "5120x2160@30Hz";
            scale = 1.6;
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
    ];
  };
}
