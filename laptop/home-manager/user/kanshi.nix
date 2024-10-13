{ pkgs,  ... }:
{

  services.kanshi = {
    enable = true;
    systemdTarget = "niri.service";

    settings = [
      { profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            scale = 1.6;
            status = "enable";
          }
        ];
      }
      { profile.name = "home_office_1";
        profile.outputs = [
          {
            criteria = "DP-1";
            status = "enable";
          }
          {
            criteria = "eDP-1";
            scale = 1.0;
            status = "disable";
          }
        ];
      }
      { profile.name = "home_office_2";
        profile.outputs = [
          {
            criteria = "DP-2";
            status = "enable";
          }
          {
            criteria = "eDP-1";
            scale = 1.0;
            status = "disable";
          }
        ];
      }
    ];
  };

}
