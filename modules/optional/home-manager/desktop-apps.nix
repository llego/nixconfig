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
    extensions = with pkgs.vscode-extensions; [
      yzhang.markdown-all-in-one
      mechatroner.rainbow-csv
      pkief.material-icon-theme
      jnoortheen.nix-ide
      kamadorueda.alejandra
    ];
    userSettings = {
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
