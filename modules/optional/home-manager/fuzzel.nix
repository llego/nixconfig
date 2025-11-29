{
  config,
  lib,
  ...
}: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main.font = lib.mkForce "monospace";
      main.prompt = "  ";
      main.terminal = "alacritty";
      main."icon-theme" = "${config.gtk.iconTheme.name}";
      main."icons-enabled" = true;
      main."image-size-ratio" = 0.2;
      main.width = 40;
      main."horizontal-pad" = 20;
      main."vertical-pad" = 20;
      main."inner-pad" = 5;
      main."line-height" = 20;
      main."border-radius" = 20;
    };
  };
}
