{
  pkgs,
  inputs,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration-laptop.nix
    ./hardware.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = "24.05";
  home.stateVersion = "24.05";
}
