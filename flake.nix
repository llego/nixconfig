{
  description = "llego's nix config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org?priority=2"
      #"https://cuda-maintainers.cachix.org?priority=1"
      "https://niri.cachix.org?priority=1"
      "https://llego.cachix.org?priority=1"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      #"cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "llego.cachix.org-1:WzO82OCKQr+mNapPewBwEeN5Ui5vPjduTIYfrD0YFwQ="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    niri.url = "github:sodiboo/niri-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    bandsnatch.url = "github:ovyerus/bandsnatch";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    username = "llego";
  in {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          hostname = "laptop";
        };
      };

      gamestation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/gamestation.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          hostname = "gamestation";
        };
      };

      # nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage' --system aarch64-linux --accept-flake-config
/*
        rpi5 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/rpi5.nix
          ];
          specialArgs = {
            inherit inputs;
            inherit username;
            hostname = "rpi5";
          };
        };
*/

rpi5 = let
  system = "aarch64-linux";

  # Custom overlay to override pysilero-vad in python312
  my-python-overlay = (final: prev: {
    python312 = prev.python312.override {
      packageOverrides = python-final: python-prev: {
        pysilero-vad = python-prev.pysilero-vad.overridePythonAttrs (_: {
          doCheck = prev.stdenv.buildPlatform.system != "aarch64-linux";
          dontUsePythonImportsCheck = prev.stdenv.buildPlatform.system == "aarch64-linux";
        });
      };
    };
  });

  # Combine overlays from raspberry-pi-nix with our custom overlay
  combinedOverlays = builtins.attrValues inputs.raspberry-pi-nix.overlays ++ [ my-python-overlay ];

  pkgs = import nixpkgs {
    inherit system;
    overlays = combinedOverlays;
  };

in nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    {
      nixpkgs.pkgs = pkgs;
    }

    ./hosts/rpi5.nix
  ];

  specialArgs = {
    inherit inputs username;
    hostname = "rpi5";
  };
};



};
      packages.x86_64-linux = {
        test-iso = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            ./hosts/laptop.nix
          ];
          format = "iso";
          specialArgs = {
            inherit inputs;
            inherit username;
            hostname = "testhost";
          };
        };
      };
    };
}
