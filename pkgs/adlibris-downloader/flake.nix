{
  description = "Download watermarked EPUBs from Adlibris and send to Booklore bookdrop";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    
    # Python environment with Playwright
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      playwright
      
    ]);
  in {
    packages.${system} = rec {
      # Original curl-based downloader  
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

      # New Playwright-based downloader
      adlibris-browser = pkgs.writeShellApplication {
        name = "adlibris-browser";
        text = ''
          # Install Playwright browsers if not already installed
          export PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright
          if [ ! -d "$PLAYWRIGHT_BROWSERS_PATH" ]; then
            echo "Installing Playwright browsers..."
            ${pythonEnv}/bin/playwright install firefox
          fi
          
          # Run the Python script
          ${pythonEnv}/bin/python ${./adlibris-browser.py} "$@"
        '';
        runtimeInputs = with pkgs; [
          pythonEnv
          rsync
          coreutils
        ];
      };

      default = adlibris-browser;  # Make the browser version default
    };
  };
}
