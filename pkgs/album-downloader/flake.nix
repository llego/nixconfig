{
  description = "Download albums from bandcamp and rsync to server";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.${system} = rec {
      album-downloader = pkgs.writeShellApplication {
        name = "album-downloader";
        text = builtins.readFile ./album-downloader.sh;
        runtimeInputs = with pkgs; [
          bandcamp-collection-downloader
          rsync
        ];
      };

      default = album-downloader;
    };
  };
}
