{
  description = "YLE Areena to Sonarr importer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      python = pkgs.python3;
      package = python.pkgs.buildPythonApplication {
        pname = "yle-sonarr-import";
        version = "0.1.0";
        src = ./.;
        pyproject = true;

        build-system = with python.pkgs; [
          setuptools
          wheel
        ];

        dependencies = with python.pkgs; [
          pyyaml
        ];

        nativeBuildInputs = [pkgs.makeWrapper];
        nativeCheckInputs = with python.pkgs; [pytestCheckHook];

        postInstall = ''
          wrapProgram $out/bin/yle-sonarr-import \
            --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.yle-dl pkgs.ffmpeg]}
        '';
      };
    in {
      default = package;
      yle-sonarr-import = package;
    });

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/yle-sonarr-import";
        meta.description = "Run the YLE Areena to Sonarr importer";
      };
      yle-sonarr-import = self.apps.${system}.default;
    });

    checks = forAllSystems (system: {
      default = self.packages.${system}.default;
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      pythonEnv = pkgs.python3.withPackages (ps: [
        ps.pytest
        ps.pyyaml
      ]);
    in {
      default = pkgs.mkShell {
        packages = [
          pythonEnv
          pkgs.ffmpeg
          pkgs.yle-dl
        ];
        shellHook = ''
          export PYTHONPATH=${./src}''${PYTHONPATH:+:$PYTHONPATH}
        '';
      };
    });
  };
}
