{
  inputs,
  pkgs,
  username,
  ...
}: {
  imports = [
    inputs.noctalia.nixosModules.default
    ./swayidle.nix
  ];

  environment.systemPackages = with pkgs; [
    pavucontrol
    xwayland-satellite
    wayland-utils
    fuzzel # config in dotfiles
    brightnessctl
    wlr-randr
    wdisplays
    wl-clipboard
    kanshi # config in dotfiles
    numix-cursor-theme
    papirus-icon-theme
    nwg-look # Needed for setting gtk theme in Noctalia
    adw-gtk3 # Needed for setting gtk theme in Noctalia
    pywalfox-native # Needed by Noctalia to theme Firefox and Thunderbird
    # swayidle
  ];

  # Niri window manager
  # Config in dotfiles
  programs.niri.enable = true;

  /*
  # DankMaterialShell
  programs.dms-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    # enableCalendarEvents = true; # Calendar integration (khal)
  };
  */

  # Noctalia shell
  # Config in dotfiles
  services.noctalia-shell.enable = true;

  # Environment variables
  environment.sessionVariables = {
    TERMINAL = "alacritty";
    # SAL_USE_VCLPLUGIN = "kf5"; # try to get dark mode working in libreoffice
    NIXOS_OZONE_WL = "1"; # For electron applications such as vscode
    QT_QPA_PLATFORMTHEME = "gtk3"; # In order to get icons working in Noctalia: https://docs.noctalia.dev/getting-started/faq/
  };

  # Extra Portal Configuration
  # xdg-desktop-portal provides a portal frontend service for Flatpak, Snap, and possibly other desktop containment/sandboxing frameworks.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      # pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal
    ];
  };

  services = {
    blueman.enable = true; # Bluetooth
    gvfs.enable = true; # Nautilus sftp
    greetd = {
      enable = true;
      settings.default_session = {
        user = username;
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --remember \
            --remember-session \
            --cmd niri-session \
            --theme 'border=#c4a7e7;text=#e0def4;prompt=#9ccfd8;time=#6e6a86;action=#31748f;button=#f6c177;container=#191724;input=#eb6f92'
        '';
      };
    };
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-color-emoji
      inter
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Inter Display Medium"];
        monospace = ["FiraCode Nerd Font"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };

  # home-manager.users.${username} = {
  # gtk = {
  #   enable = true;
  #   font = {
  #     package = pkgs.inter;
  #     name = "Inter Display Regular";
  #     size = 10;
  #   };
  #   colorScheme = "dark";
  #   # theme = {
  #   # package = pkgs.tokyonight-gtk-theme;
  #   # name = "Tokyonight-Dark";
  #   # };
  #   iconTheme = {
  #     package = pkgs.papirus-icon-theme;
  #     name = "Papirus-Dark";
  #   };
  #   cursorTheme = {
  #     package = pkgs.numix-cursor-theme;
  #     name = "Numix-Cursor-Light";
  #     size = 24;
  #   };
  # };

  # xdg = {
  #   mimeApps.enable = true;
  #   mimeApps.defaultApplications = {
  #     "default-web-browser" = "firefox.desktop";
  #     "text/plain" = "org.gnome.TextEditor.desktop";
  #     "text/html" = "firefox.desktop";
  #     "x-scheme-handler/http" = "firefox.desktop";
  #     "x-scheme-handler/https" = "firefox.desktop";
  #     "x-scheme-handler/about" = "firefox.desktop";
  #     "x-scheme-handler/unknown" = "firefox.desktop";
  #     "x-scheme-handler/mailto" = "proton-mail.desktop";
  #     "application/xhtml+xml" = "firefox.desktop";
  #     "application/octet-stream" = "vlc.desktop";
  #     "application/pdf" = "org.gnome.Evince.desktop";
  #     "image/jpeg" = "org.gnome.Loupe.desktop";
  #     "image/png" = "org.gnome.Loupe.desktop";
  #     "image/gif" = "org.gnome.Loupe.desktop";
  #     "image/webp" = "org.gnome.Loupe.desktop";
  #     "image/bmp" = "org.gnome.Loupe.desktop";
  #   };
  #   configFile."mimeapps.list".force = true;
  # };
  # };

  # qt = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };

  # programs.dconf.profiles.user.databases = [
  #   {
  #     settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  #   }
  # ];
}
