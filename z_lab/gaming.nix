{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    #inputs.jovian.nixosModules.jovian.default
    #inputs.jovian.nixosModules.steam.default
  ];

  # Steam
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  programs.gamescope.capSysNice = true;

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  #jovian.steam.enable = true;
  #jovian.steam.desktopSession = "niri-session";

  # Game related packages
  environment.systemPackages = with pkgs; [
    mangohud
    protonup
    lutris
    xwayland-run
    mesa-demos
  ];

  # Flathub and boxflat
  services.flatpak = {
    enable = true;
    packages = [
      "io.github.lawstorant.boxflat"
    ];
  };
}
