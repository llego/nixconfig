{pkgs, ...}: {
  # System packages
  environment.systemPackages = with pkgs; [
    usbutils
    stow
    atool
    btop
    bat
    lsd
    ncdu
    jq
    wget
    curl
    helix # text editor
    yazi # file manager
    lazygit # git
  ];

  environment.sessionVariables = {
    EDITOR = "hx"; # Set default text editor
  };
}
