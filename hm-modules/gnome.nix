{config, pkgs, ...}:
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
      exec = "kitty -- ssh llego@docker.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-truenas = {
      name = "truenas.home";
      genericName = "ssh into admin@truenas.home";
      exec = "kitty -- ssh admin@truenas.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-christiansandberg = {
      name = "christiansandberg.fi";
      exec = "kitty -- ssh llego@christiansandberg.fi";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpi3 = {
      name = "rpi3.home";
      exec = "kitty -- ssh pi@rpi3.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpi4 = {
      name = "rpi4.home";
      exec = "kitty -- ssh pi@rpi4.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  ssh-rpizero = {
      name = "rpizero.home";
      exec = "kitty -- ssh pi@rpizero.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  };

  # Gnome settings
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/wm/keybindings" = {
        show-desktop = [ "<Super>d" ];
        move-to-workspace-left = [ "<Shift><Super>Left" ];
        move-to-workspace-right = [ "<Shift><Super>Right" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Kitty";
        command = "kitty";
        binding = "<Super>Return";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Kitty";
        command = "kitty";
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Nautilus";
        command = "nautilus";
        binding = "<Super>f";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "Chromium";
        command = "chromium";
        binding = "<Super>w";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          blur-my-shell.extensionUuid
          gsconnect.extensionUuid
        ];
      };
#      "org/gnome/desktop/interface" = {
#        color-scheme = "prefer-dark";
#      };
#      "org/gnome/desktop/interface" = {
#        monospace-font-name = "JetBrainsMono Nerd Font 10";
#      };
#      "org/gnome/Console" = {
#        custom-font = "JetBrainsMono Nerd Font 10";
#      };
      "org/gnome/shell/extensions/blur-my-shell" = {
        brightness = 0.75;
        noise-amount = 0;
      };
    };
  };
  
  # Nautilus bookmarks
  xdg.configFile."gtk-3.0/bookmarks" = {
    enable = true;
    text = ''
      sftp://admin@truenas.home/mnt truenas
      sftp://llego@docker.home/mnt docker
      sftp://llego@christiansandberg.fi/opt christiansandberg.fi
      sftp://root@homeassistant.home/config homeassistant
    '';
  };
  
  # GTK
  gtk = {
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

}
