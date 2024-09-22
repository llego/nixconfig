{config, pkgs, ...}:
{
  # Packages
  home.packages = with pkgs; [ 
    bitwarden-desktop
    protonmail-desktop
    trayscale
    vlc
    (nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
    gnome-terminal
    gnome-tweaks
    gnomeExtensions.blur-my-shell
  ];
}
