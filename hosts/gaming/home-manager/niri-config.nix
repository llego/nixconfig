{
  username,
  pkgs,
  ...
}: {
  # niri msg outputs
  programs.niri.settings.outputs.HDMI-A-1 = {
    enable = true;
    scale = 1.6;
    mode = {
      width = 3840; #5120;
      height = 2160;
      refresh = 59.997;
    };
    variable-refresh-rate = false;
  };
}
