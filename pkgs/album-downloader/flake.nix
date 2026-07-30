{
  description = "Download albums from bandcamp and rsync to server";

  inputs = {
    bandsnatch = {
      url = "github:Ovyerus/bandsnatch";
    };
  };

  outputs = {
    self,
    bandsnatch,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    bandsnatchPackage = bandsnatch.packages.${system}.default;
  in {
    packages.${system} = rec {
      bandsnatch = bandsnatchPackage;

      album-downloader = pkgs.writeShellApplication {
        name = "album-downloader";
        text = builtins.readFile ./album-downloader.sh;
        runtimeInputs = with pkgs; [
          bandsnatch
          curl
          jq
          perl
          rsync
        ];
      };

      default = album-downloader;
    };
  };
}
