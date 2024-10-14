{ config, ... }:
{ 
  programs.fuzzel = {
    enable = true;
    settings = 	
      {
        main.prompt = "  ";
        main.terminal = "kitty";
        main."icon-theme" = "${config.gtk.iconTheme.name}";
        main."icons-enabled" = true;
        main."image-size-ratio" = 0.2;
        main.width = 40;
        main."horizontal-pad" = 20;
        main."vertical-pad" = 20;
        main."inner-pad" = 5;
        main."line-height" = 20;
      };
  };

}
