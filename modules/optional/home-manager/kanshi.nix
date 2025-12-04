{pkgs, ...}: {
  # Kanshi display settings for laptop display and external display
  services.kanshi = {
    enable = true;
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
            mode = "3840x2160";
            scale = 1.6;
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
      {
        profile.name = "home_office_2";
        profile.outputs = [
          {
            criteria = "DP-2";
            status = "enable";
            mode = "3840x2160";
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
