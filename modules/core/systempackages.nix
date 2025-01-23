{pkgs, ...}: {
  # System packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    htop
    xorg.xrandr
    screen
    jq
    dig
    tree
    ncdu
    alejandra
    nixd
    usbutils
    networkmanager
    cachix
  ];

  # Zsh
  programs.zsh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
