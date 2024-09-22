{ pkgs, inputs, config, ... }: 

{

  stylix.enable = true;

#  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
#  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
#  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
#  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/lime.yaml";
#  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/horizon-dark.yaml";
#  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/material-darker.yaml";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

  stylix.image = ./wallpaper_2.jpg;
   
  stylix.fonts = {
    monospace = {
      package = (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; });
      name = "JetBrainsMono Nerd Font";
    };
    serif = {
      package = pkgs.cantarell-fonts;
      name = "Cantarell Regular";
    };
    sansSerif = config.stylix.fonts.serif;
    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
    sizes = {
      terminal = 10;
      popups = 10;
      applications = 10;
      desktop = 10;
    };
  };


}
