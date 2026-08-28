{
  pkgs,
  inputs,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ungoogled-chromium
    baobab
    vlc
    # rpi-imager
    calibre
    signal-desktop

    # Libre Office
    libreoffice
    libvoikko
    hunspell
    hunspellDicts.sv-fi
    hunspellDicts.en-gb-ize
  ];

  programs.chromium = {
    enable = true;

    extraOpts = {
      BrowserGuestModeEnabled = false;
      BrowserAddPersonEnabled = false;

      BrowserSignin = 0;
      SyncDisabled = true;
      PasswordManagerEnabled = false;
      # SearchSuggestEnabled = false;
      TranslateEnabled = false;
      AutofillCreditCardEnabled = false;
    };

    initialPrefs = {
      browser = {
        show_home_button = false;
      };

      distribution = {
        skip_first_run_ui = true;
      };
    };
  };

  services.mullvad-vpn.enable = true;
  # Uncomment this to get Mullvad GUI
  # services.mullvad-vpn.package = pkgs.mullvad-vpn;
}
