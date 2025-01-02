{
  pkgs,
  hostname,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./drivers.nix
    ./home-manager
    #./../../modules/gnome-config.nix
    ./../../common-modules/niri-config.nix
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  networking.hostName = hostname;

  # Steam
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  # Game related packages
  environment.systemPackages = with pkgs; [
    mangohud
    protonup
    lutris
  ];

  # Flathub and boxflat
  services.flatpak = {
    enable = true;
    packages = ["io.github.lawstorant.boxflat"];
  };

  system.stateVersion = "24.11";
}
