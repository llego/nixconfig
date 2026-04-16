{
  pkgs,
  username,
  inputs,
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
    #bitwarden-desktop
    #protonmail-desktop
    # protonmail-bridge-gui
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

  # # Firefox
  # programs.firefox = {
  #   enable = true;
  #   policies = {
  #     DisablePocket = true;
  #     OfferToSaveLogins = false;
  #     PasswordManagerEnabled = false;
  #     DisableFirefoxScreenshots = true;
  #     DisplayBookmarksToolbar = "always";
  #     SearchBar = "unified";
  #     Preferences = {
  #       "identity.fxaccounts.toolbar.pxiToolbarEnabled" = false;
  #     };

  #     ExtensionSettings = with builtins; let
  #       extension = shortId: uuid: {
  #         name = uuid;
  #         value = {
  #           install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
  #           installation_mode = "normal_installed";
  #         };
  #       };
  #     in
  #       listToAttrs [
  #         (extension "readeck" "readeck@readeck.com")
  #         (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
  #         (extension "pywalfox" "pywalfox@frewacom.org")
  #       ];
  #     # To add additional extensions, find it on addons.mozilla.org, find
  #     # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
  #     # Then, download the XPI by filling it in to the install_url template, unzip it,
  #     # run `jq .browser_specific_settings.gecko.id manifest.json` or
  #     # `jq .applications.gecko.id manifest.json` to get the UUID
  #   };
  # };

  # Email
  programs.thunderbird.enable = true;
  services.protonmail-bridge.enable = true;
}
