{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # tidal-dl
    yle-dl
    svtplay-dl
    mediainfo
    inputs.album-downloader.packages.${pkgs.stdenv.hostPlatform.system}.album-downloader
  ];

  # tidal-dl configuration
  # home.file.tidal-dl-conf = {
  # enable = true;
  # source = ./.tidal-dl.json;
  # target = ".tidal-dl.json";
  # };

  # home.file."${config.home.homeDirectory}/bandcamp-downloader/bandcamp-collection-downloader.cache".source = config.lib.file.mkOutOfStoreSymlink /home/${username}/nixconfig/modules/optional/home-manager/downloaders/bandcamp-collection-downloader.cache;

  # home.file."${config.home.homeDirectory}/bandcamp-downloader/bandcamp.com_cookies.txt".source = config.lib.file.mkOutOfStoreSymlink /home/${username}/nixconfig/modules/optional/home-manager/downloaders/bandcamp.com_cookies.txt;
}
