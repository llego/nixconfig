{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nautilus
    gnome-text-editor
    evince
    loupe
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
    noctalia-shell # Noctalia shell
  ];

  # Niri window manager, config in dotfiles
  programs.niri.enable = true;

  # Environment variables
  environment.sessionVariables = {
    TERMINAL = "foot";
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
      pkgs.xdg-desktop-portal
    ];
  };

  services = {
    blueman.enable = true; # Bluetooth
    gvfs.enable = true; # Nautilus sftp
    greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --remember \
            --remember-session \
            --user-menu \
            --cmd niri-session \
            --theme 'border=#c4a7e7;text=#e0def4;prompt=#9ccfd8;time=#6e6a86;action=#31748f;button=#f6c177;container=#191724;input=#eb6f92'
        '';
      };
    };
  };

  # Cache directory for tuigreet --remember functionality
  systemd.tmpfiles.rules = [
    "d /var/cache/tuigreet 0755 greeter greeter -"
  ];

  # MIME type associations
  xdg.mime = {
    enable = true;
    defaultApplications = {
      # Web browser (Zen)
      "default-web-browser" = "zen.desktop";
      "text/html" = "zen.desktop";
      "application/xhtml+xml" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";

      # Text files (GNOME Text Editor)
      "text/plain" = "org.gnome.TextEditor.desktop";
      "text/markdown" = "org.gnome.TextEditor.desktop";
      "text/x-markdown" = "org.gnome.TextEditor.desktop";
      "text/x-log" = "org.gnome.TextEditor.desktop";
      "application/json" = "org.gnome.TextEditor.desktop";
      "application/xml" = "org.gnome.TextEditor.desktop";

      # Documents
      "application/pdf" = "org.gnome.Evince.desktop";

      # Images (GNOME Loupe)
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";

      # Video (VLC)
      "application/octet-stream" = "vlc.desktop";
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

  programs.foot = {
    enable = true;
    theme = "rose-pine";
    settings = {
      main = {
        font = "FiraCode Nerd Font:size=10";
        pad = "10x5";
        title = "foot";
        app-id = "foot";
      };
      bell = {
        urgent = false;
        notify = false;
      };
      scrollback = {
        lines = 250000;
        indicator-position = "relative";
        indicator-format = "{percentage}%";
      };
      cursor = {
        style = "block";
        blink = false;
      };
      mouse = {
        hide-when-typing = true;
      };
      csd = {
        preferred = "server";
        size = 26;
      };
      key-bindings = {
        scrollback-up-page = "Shift+Page_Up";
        scrollback-down-page = "Shift+Page_Down";
        scrollback-up-line = "Shift+Up";
        scrollback-down-line = "Shift+Down";
        clipboard-copy = "Control+Shift+c";
        clipboard-paste = "Control+Shift+v";
        primary-paste = "Shift+Insert";
        search-start = "Control+Shift+f";
        font-increase = "Control+plus Control+equal";
        font-decrease = "Control+minus";
        font-reset = "Control+0";
        spawn-terminal = "Control+Shift+n";
        show-urls-launch = "Control+Shift+o";
        quit = "Control+Shift+q";
      };
      search-bindings = {
        cancel = "Escape";
        commit = "Return";
        find-prev = "Control+Shift+n";
        find-next = "Control+n";
      };
      url-bindings = {
        cancel = "Escape Control+c";
        toggle-url-visible = "Control+Shift+u";
      };
    };
  };

  # nautilus-open-any-terminal
  # https://github.com/Stunkymonkey/nautilus-open-any-terminal
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "foot";
  };
}
