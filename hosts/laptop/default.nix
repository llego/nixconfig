{
  imports = [
    ./hardware-configuration.nix
    ./drivers.nix
    ./home-manager
    ./../../modules/niri-config.nix
    ./../../modules/wifi-networks.nix
  ];

  system.stateVersion = "24.05";
}
