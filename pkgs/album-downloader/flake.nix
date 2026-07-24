{
  description = "Download albums from bandcamp and rsync to server";

  inputs = {
    bandsnatch = {
      url = "github:Ovyerus/bandsnatch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    bandsnatch,
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
          bandsnatch.packages.${system}.default
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
