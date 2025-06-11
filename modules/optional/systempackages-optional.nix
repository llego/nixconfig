{pkgs, ...}: {
  # System packages
  environment.systemPackages = with pkgs; [
    networkmanager
    cachix
    jq
    dig
    tree
    ncdu
    unzip
    fastfetch
    neofetch
  ];
}
