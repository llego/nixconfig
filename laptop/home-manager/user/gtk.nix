{ pkgs, ... }:
{
  gtk = {
    gtk3 = {
      #extraConfig.gtk-application-prefer-dark-theme = true;
      bookmarks = [
        "file:///home/llego/nixconfig nixconfig"
        "sftp://admin@truenas.home/mnt truenas"
        "sftp://llego@docker.home/mnt docker"
        "sftp://llego@christiansandberg.fi/opt christiansandberg.fi"
        "sftp://root@homeassistant.home/config homeassistant"
        "davs://dav.cri.su/ dav.cri.su"
      ];
    };
    iconTheme = {
      #package = pkgs.kdePackages.breeze-icons;
      #package = pkgs.gnome.adwaita-icon-theme;
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
  };
  
}
