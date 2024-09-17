{config, lib, pkgs, ...}:
{
  # Application icons to Gnome menu
  targets.genericLinux.enable = true;
  xdg.mime.enable = true;
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share/applications" ];

  xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = "proton-mail.desktop";
      "text/html" = "chromium-browser.desktop";
      "application/xhtml+xml" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
  };

  xdg.desktopEntries = {
    ssh-docker = {
      name = "docker.home";
      genericName = "ssh into llego@docker.home";
      exec = "kgx -- ssh llego@docker.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-truenas = {
      name = "truenas.home";
      genericName = "ssh into admin@truenas.home";
      exec = "kgx -- ssh admin@truenas.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-christiansandberg = {
      name = "christiansandberg.fi";
      exec = "kgx -- ssh llego@christiansandberg.fi";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpi3 = {
      name = "rpi3.home";
      exec = "kgx -- ssh pi@rpi3.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpi4 = {
      name = "rpi4.home";
      exec = "kgx -- ssh pi@rpi4.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpizero = {
      name = "rpizero.home";
      exec = "kgx -- ssh pi@rpizero.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  };

  # Gnome settings
  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Console";
        command = "kgx";
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Nautilus";
        command = "nautilus";
        binding = "<Super>f";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          blur-my-shell.extensionUuid
          gsconnect.extensionUuid
        ];
      };
      "org/gnome/shell/extensions/blur-my-shell" = {
        brightness = 0.75;
        noise-amount = 0;
      };
      "org/gnome/Console" = {
        custom-font = "JetBrainsMono Nerd Font 10";
      };
    };
  };
  
  # Nautilus bookmarks
  xdg.configFile."gtk-3.0/bookmarks" = {
    enable = true;
    text = ''
      sftp://admin@truenas.home/mnt truenas
      sftp://llego@docker.home/mnt docker
      sftp://christiansandberg.fi/opt christiansandberg.fi
    '';
  };
  
}
