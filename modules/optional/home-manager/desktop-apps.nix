{
  pkgs,
  username,
  hostname,
  ...
}: {
  # Packages
  home.packages = with pkgs; [
    bitwarden-desktop
    protonmail-desktop
    vlc
    libreoffice
    libvoikko
    hunspell
    hunspellDicts.sv-fi
    hunspellDicts.en-gb-ize
  ];

  # File manager bookmarks and icons
  gtk = {
    gtk3 = {
      bookmarks = [
        "file:///home/llego/nixconfig nixconfig"
        "sftp://llego@truenas.home/mnt truenas"
        "sftp://llego@docker.home/mnt docker"
        "sftp://llego@christiansandberg.fi/opt christiansandberg.fi"
        "sftp://root@homeassistant.home/config homeassistant"
        "sftp://llego@debian.home debian"
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

  xdg.desktopEntries = {
    ssh-truenas = {
      name = "truenas.home";
      genericName = "ssh into llego@truenas.home";
      exec = "alacritty -e ssh llego@truenas.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-christiansandberg = {
      name = "christiansandberg.fi";
      exec = "alacritty -e ssh llego@christiansandberg.fi";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpi3 = {
      name = "rpi3.home";
      exec = "alacritty -e ssh pi@rpi3.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpi4 = {
      name = "rpi4.home";
      exec = "alacritty -e ssh pi@rpi4.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpizero = {
      name = "rpizero.home";
      exec = "alacritty -e ssh llego@rpizero.home";
      terminal = false;
      icon = "utilities-terminal";
    };
    ssh-rpizero2 = {
      name = "rpizero2.home";
      exec = "alacritty -e ssh llego@rpizero2.home";
      terminal = false;
      icon = "utilities-terminal";
    };
  };

  programs.chromium = {
    enable = true;
    extensions = [
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
      {id = "fnaicdffflnofjppbagibeoednhnbjhg";} # Floccus bookmarks sync
      {id = "cclelndahbckbenkjhflpdbgdldlbecc";} # get cookies locally
      {
        id = "dcpihecpambacapedldabdbpakmachpb";
        updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
      }
    ];
  };

  /*
  programs.brave = {
    enable = true;
    package = pkgs.brave;

    extensions = [
      # Bitwarden
      "nngceckbapebfimnlniiiahkandclblb"

      # Floccus bookmarks sync
      "fnaicdffflnofjppbagibeoednhnbjhg"
    ];
  };
  */

  programs.alacritty = {
    enable = true;
    settings = {
      window.padding = {
        x = 10;
        y = 10;
      };
      window.dynamic_padding = true;
      #window.dimensions = {
      #  lines = 3;
      #  columns = 200;
      #};
      #keyboard.bindings = [
      #  {
      #    key = "K";
      #    mods = "Control";
      #    chars = "\\u000c";
      #  }
      #];
    };
  };

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      yzhang.markdown-all-in-one
      mechatroner.rainbow-csv
      pkief.material-icon-theme
      jnoortheen.nix-ide
      kamadorueda.alejandra
    ];
    profiles.default.userSettings = {
      "nix.serverPath" = "nixd";
      "nix.enableLanguageServer" = true;
      "nix.serverSettings" = {
        "nixd" = {
          "formatting" = {
            "command" = ["alejandra"];
          };
          "options" = {
            /*
            By default, this entry will be read from `import <nixpkgs> { }`.
            You can write arbitrary Nix expressions here, to produce valid "options" declaration result.
            Tip: for flake-based configuration, utilize `builtins.getFlake`
            */
            "nixos" = {
              "expr" = "(builtins.getFlake \"/home/${username}/nixconfig/flake.nix\").nixosConfigurations.${hostname}.options";
            };
          };
        };
      };
      "git.confirmSync" = false;
      "explorer.confirmDelete" = false;
      "update.mode" = "none";
      "extensions.autoCheckUpdates" = false;
      "files.enableTrash" = false;
      "explorer.confirmDragAndDrop" = false;
    };
  };
}
