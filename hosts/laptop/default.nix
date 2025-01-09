{
  imports = [
    ./hardware-configuration.nix
    ./drivers.nix
    ./home-manager
    ./../../common-modules/niri-config.nix
    ./../../common-modules/wifi-networks.nix
  ];

  system.stateVersion = "24.05";
}
