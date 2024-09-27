{config, pkgs, ...}:
{
  # Packages
  home.packages = with pkgs; [ 
    bitwarden-desktop
    protonmail-desktop
    trayscale
    vlc
#    (nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
    gnome-tweaks
    gnomeExtensions.blur-my-shell
  ];

#  programs.gnome-terminal.enable = true;

}
