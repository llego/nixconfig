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
    brave
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

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      #dynamic_background_opacity = true;
      enable_audio_bell = false;
      mouse_hide_wait = "-1.0";
      window_padding_width = 10;
      #background_opacity = "0.5";
      #draw_minimal_borders = true;
      hide_window_decorations = true;
      window_margin_width = 5;
      tab_bar_style = "slant";
    };
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      yzhang.markdown-all-in-one
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
    };
  };
}
