{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix.enable = true;

  # Color theme, see https://tinted-theming.github.io/tinted-gallery/
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/lime.yaml";
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/horizon-dark.yaml";
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/material-darker.yaml";
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";

  # Wallapaper
  #stylix.image = ./wallpaper-blue.jpg;
  #stylix.image = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
  stylix.image = ./mountains4k.jpg;

  stylix.polarity = "dark";

  stylix.opacity.popups = 0.8;

  stylix.cursor = {
    package = pkgs.numix-cursor-theme;
    name = "Numix-Cursor-Light";
    size = 24;
  };

  /*
  stylix.iconTheme = {
    enable = true;
    package = pkgs.papirus-icon-theme;
    dark = "Papirus-Dark";
    light = "Papirus-Light";
  };
  */

  stylix.fonts = {
    monospace = {
      #package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "DroidSansMono"];};
      #name = "JetBrainsMono Nerd Font";
      # New syntax for v. 25
      package = pkgs.nerd-fonts.droid-sans-mono;
      name = "DroidSansM Nerd Font Mono";
    };
    serif = {
      package = pkgs.cantarell-fonts;
      name = "Cantarell Regular";
    };
    sansSerif = config.stylix.fonts.serif;
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
    sizes = {
      terminal = 10;
      popups = 10;
      applications = 10;
      desktop = 10;
    };
  };

  #stylix.opacity.terminal = 0.95;
}
