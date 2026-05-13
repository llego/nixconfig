{
  description = "Download watermarked EPUBs from Adlibris and send to Booklore bookdrop";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.${system} = rec {
      adlibris-downloader = pkgs.writeShellApplication {
        name = "adlibris-downloader";
        text = builtins.readFile ./adlibris-downloader.sh;
        runtimeInputs = with pkgs; [
          curl
          fzf
          rsync
          sqlite
          gnused
          gnugrep
          coreutils
        ];
      };

      default = adlibris-downloader;
    };
  };
}
