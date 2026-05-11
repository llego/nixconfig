{
  pkgs,
  inputs,
  username,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    # CLI
    dig
    parted
    nitch
    usbutils
    atool
    opencode

    # Nix stuff
    nixd
    alejandra

    # Graphical
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    baobab
    vlc
    # rpi-imager
    calibre

    # Libre Office
    libreoffice
    libvoikko
    hunspell
    hunspellDicts.sv-fi
    hunspellDicts.en-gb-ize
  ];

  # Firefox
  programs.firefox = {
    enable = true;
    policies = {
      DisablePocket = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      #DisableFirefoxAccounts = true;
      #DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      DisplayBookmarksToolbar = "always";
      SearchBar = "unified";
      Preferences = {
        "identity.fxaccounts.toolbar.pxiToolbarEnabled" = false;
      };

      # EXTENSIONS
      # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/7?page=2
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = with builtins; let
        extension = shortId: uuid: {
          name = uuid;
          value = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
            installation_mode = "normal_installed";
          };
        };
      in
        listToAttrs [
          (extension "wallabagger" "{7a7b1d36-d7a4-481b-92c6-9f5427cb9eb1}")
          (extension "readeck" "readeck@readeck.com")
          (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
        ];
      # To add additional extensions, find it on addons.mozilla.org, find
      # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
      # Then, download the XPI by filling it in to the install_url template, unzip it,
      # run `jq .browser_specific_settings.gecko.id manifest.json` or
      # `jq .applications.gecko.id manifest.json` to get the UUID
    };
  };

  # Email
  programs.thunderbird.enable = true;
  services.protonmail-bridge.enable = true;

  # Application dotfiles
  hjem.users.${username}.xdg.config.files = let
    dots = "${./core/dots}";
  in {
    # OpenCode configuration files
    "opencode/opencode.json".source = dots + "/opencode/opencode.json";
    "opencode/AGENTS.md".source = dots + "/opencode/AGENTS.md";
    "opencode/agent/code-reviewer.md".source = dots + "/opencode/agent/code-reviewer.md";
  };
}
