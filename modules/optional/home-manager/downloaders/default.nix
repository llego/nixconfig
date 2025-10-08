{
  inputs,
  pkgs,
  username,
  config,
  ...
}: {
  home.packages = with pkgs; [
    tidal-dl
    yle-dl
    svtplay-dl
    mediainfo
    (writeShellScriptBin "album-downloader" (builtins.readFile ./album-downloader.sh))
    inputs.bandsnatch.packages."${pkgs.system}".default
  ];

  # tidal-dl configuration
  home.file.tidal-dl-conf = {
    enable = true;
    source = ./.tidal-dl.json;
    target = ".tidal-dl.json";
  };

  home.file."${config.home.homeDirectory}/bandcamp-downloader/bandcamp-collection-downloader.cache".source = config.lib.file.mkOutOfStoreSymlink /home/${username}/nixconfig/modules/optional/home-manager/downloaders/bandcamp-collection-downloader.cache;
  home.file."${config.home.homeDirectory}/bandcamp-downloader/bandcamp.com_cookies.txt".source = config.lib.file.mkOutOfStoreSymlink /home/${username}/nixconfig/modules/optional/home-manager/downloaders/bandcamp.com_cookies.txt;
}
