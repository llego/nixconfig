{
  pkgs,
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

  # Email
  programs.thunderbird.enable = true;
  services.protonmail-bridge.enable = true;
}
