{
  pkgs,
  username,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    # CLI
    bitwarden-cli
    dig
    unzip
    fastfetch
    cachix
    parted
    nitch

    # Graphical
    nautilus
    gnome-text-editor
    baobab
    alacritty
    vscodium
    # chromium
    papirus-icon-theme
    #bitwarden-desktop
    #protonmail-desktop
    vlc
    rpi-imager
    evince
    loupe
    calibre
    networkmanager
    # protonmail-bridge-gui

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
      DisableFirefoxScreenshots = true;
      DisplayBookmarksToolbar = "always";
      SearchBar = "unified";
      Preferences = {
        "identity.fxaccounts.toolbar.pxiToolbarEnabled" = false;
      };

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

  # nautilus-open-any-terminal
  # https://github.com/Stunkymonkey/nautilus-open-any-terminal
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };

  # Email
  programs.thunderbird.enable = true;
  services.protonmail-bridge.enable = true;
}
