{
  lib,
  pkgs,
  username,
  inputs,
  dots,
  ...
}: {
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  environment.systemPackages =
    (with pkgs; [
      nautilus
      gnome-text-editor
      evince
      loupe
      pavucontrol
      xwayland-satellite
      wayland-utils
      gotify-desktop # Config in dotfiles
      brightnessctl
      wlr-randr
      wdisplays
      wl-clipboard
      kanshi # Config in dotfiles
      kdePackages.qt6ct
      numix-cursor-theme
      papirus-icon-theme
      nwg-look # Needed for setting gtk theme in Noctalia
      adw-gtk3 # Needed for setting gtk theme in Noctalia
    ])
    ++ [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  environment.pathsToLink = ["/share/wayland-sessions"];

  programs = {
    # Niri window manager, config in dotfiles
    niri.enable = true;

    noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "Niri";
        user.default = username;
        cursor = {
          theme = "Numix-Cursor";
          size = 24;
          path = "${pkgs.numix-cursor-theme}/share/icons";
        };
        keyboard.layout = "fi";
        idle.timeout = 300;
      };
    };
  };

  # Environment variables
  environment.sessionVariables = {
    TERMINAL = "foot";
    NIXOS_OZONE_WL = "1"; # For electron applications such as vscode
    QT_QPA_PLATFORMTHEME = "qt6ct"; # Let Noctalia's Qt/KColorScheme templates drive Qt appearance.
  };

  services = {
    gvfs.enable = true; # Nautilus sftp
    greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
      };
    };
  };

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
      # nerd-fonts.droid-sans-mono
      # nerd-fonts.fira-code
      maple-mono.NF-unhinted
      noto-fonts
      noto-fonts-color-emoji
      inter
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Inter"];
        # monospace = ["FiraCode Nerd Font"];
        monospace = ["Maple Mono NF Light"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };

  programs.foot = {
    enable = true;
    theme = "rose-pine";
    settings = {
      main = {
        font = "Maple Mono NF Light:size=10";
        pad = "10x10";
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
        indicator-format = "percentage";
      };
      colors-dark = {
        alpha = "0.90";
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

  # Desktop environment dotfiles
  hjem.users.${username} = let
    wallpaperDir = dots + "/noctalia/wallpapers";
    wallpaperFiles = builtins.attrNames (lib.filterAttrs (_: type: type == "regular") (builtins.readDir wallpaperDir));
    wallpaperMappings = builtins.listToAttrs (map (file: {
        name = "noctalia/wallpapers/${file}";
        value.source = dots + "/noctalia/wallpapers/${file}";
      })
      wallpaperFiles);
  in {
    xdg.config.files =
      {
        "niri/config.kdl".source = dots + "/niri/config.kdl";
        # "kanshi/config".source = dots + "/kanshi/config"; # Config moved from dotfile to laptop/default.nix
        "gtk-3.0/bookmarks".source = dots + "/gtk-3.0/bookmarks";
        "noctalia/config.toml".source = dots + "/noctalia/config.toml";
        "gotify-desktop/config.toml".source = dots + "/gotify-desktop/config.toml";
      }
      // wallpaperMappings;

    # SSH shortcuts (application desktop files)
    xdg.data.files = {
      "applications/ssh-christiansandberg.desktop".source = dots + "/applications/ssh-christiansandberg.desktop";
      "applications/ssh-crisuflix.desktop".source = dots + "/applications/ssh-crisuflix.desktop";
      "applications/ssh-rpi3.desktop".source = dots + "/applications/ssh-rpi3.desktop";
      "applications/ssh-rpi5.desktop".source = dots + "/applications/ssh-rpi5.desktop";
      "applications/ssh-rpizero2.desktop".source = dots + "/applications/ssh-rpizero2.desktop";
    };
  };
}
