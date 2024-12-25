{username, ...}: {
  home-manager.users.${username} = {
    home.stateVersion = "24.11";

    programs.niri.settings.outputs."HDMI-A-1" = {
      enable = true;
      scale = 1.6;
      mode = {
        width = 3840;
        height = 2160;
        refresh = 59.997;
      };
      variable-refresh-rate = true;
    };
  };
}
