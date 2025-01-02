{...}: {
  # niri msg outputs
  programs.niri.settings.outputs."DP-3" = {
    enable = true;
    scale = 1.6;
    mode = {
      width = 5120;
      height = 2160;
      refresh = 60.0;
    };
    variable-refresh-rate = false;
  };
}
