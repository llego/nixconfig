{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    tidal-dl
    yle-dl
    svtplay-dl
    mediainfo
    (writeShellScriptBin "bandcamp-collection" (builtins.readFile ./bandcamp-collection.sh))
    inputs.bandsnatch.packages."${pkgs.system}".default
  ];

  # tidal-dl configuration
  home.file.tidal-dl-conf = {
    enable = true;
    source = ./.tidal-dl.json;
    target = ".tidal-dl.json";
  };
}
