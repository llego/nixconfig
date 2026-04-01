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
    nautilus
    gnome-text-editor
    baobab
    #bitwarden-desktop
    #protonmail-desktop
    # protonmail-bridge-gui
    vlc
    # rpi-imager
    evince
    loupe
    calibre

    # Libre Office
    libreoffice
    libvoikko
    hunspell
    hunspellDicts.sv-fi
    hunspellDicts.en-gb-ize
  ];

  programs.foot = {
    enable = true;
    theme = "rose-pine";
    # theme = "tokyonight-night";
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

  # nautilus-open-any-terminal
  # https://github.com/Stunkymonkey/nautilus-open-any-terminal
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };

  # Email
  programs.thunderbird.enable = true;
  services.protonmail-bridge.enable = true;
}
