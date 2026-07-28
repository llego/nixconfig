{
  pkgs,
  inputs,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
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

  services.mullvad-vpn.enable = true;
  # Uncomment this to get Mullvad GUI
  # services.mullvad-vpn.package = pkgs.mullvad-vpn;
}
