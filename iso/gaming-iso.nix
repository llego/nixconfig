{
  pkgs,
  hostname,
  username,
  ...
}: {
  imports = [
    ./../hosts/gaming/drivers.nix
    #./../hosts/gaming/home-manager/niri-config.nix
    #./../hosts/gaming/home-manager/swayidle.nix
    ./../modules/niri-config.nix
  ];

  home-manager.users.${username}.home.stateVersion = "24.11";

  networking.hostName = hostname;

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup
    lutris
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  system.stateVersion = "24.11";
}
