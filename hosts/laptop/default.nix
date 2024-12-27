{
  pkgs,
  inputs,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./drivers.nix
    ./home-manager
    ./../../common-modules/niri-config.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = "24.05";
}
