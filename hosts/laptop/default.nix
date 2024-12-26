{
  pkgs,
  inputs,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration-laptop.nix
    ./hardware.nix
    ./home-manager
    ./../../common/niri-config.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = "24.05";
}
