{
  description = "llego's nix config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://niri.cachix.org"
      "https://llego.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "llego.cachix.org-1:WzO82OCKQr+mNapPewBwEeN5Ui5vPjduTIYfrD0YFwQ="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-24.11";
    niri.url = "github:sodiboo/niri-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    bandsnatch.url = "github:ovyerus/bandsnatch";
    #nixos-generators.url = "github:nix-community/nixos-generators";
    #nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    #nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    #raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    username = "llego";
    git-email = "github.login@cri.su";
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
          inherit git-email;
          hostname = "laptop";
        };
      };

      gaming = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/gamestation.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit git-email;
          hostname = "gamestation";
        };
      };
      /*
      rpi-example = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          inputs.raspberry-pi-nix.nixosModules.raspberry-pi
          ./basic-rpi4-config.nix
          ./modules/core
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit git-email;
          hostname = "rpi4";
        };
      };
      */
    };

    /*
    packages.x86_64-linux = {
      gaming-iso = inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./iso/gaming-iso.nix
        ];
        format = "iso";
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit git-email;
          hostname = "gaming";
        };
      };
    };

    # Docker jail on TrueNAS
    # Activate: home-manager switch --flake ~/nixconfig#llego@docker
    homeConfigurations = {
      "${username}@docker" = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./laptop/home-manager/user
          {
            programs.home-manager.enable = true;
            home.username = "${username}";
            home.homeDirectory = "/home/${username}";
          }
        ];
        extraSpecialArgs = {
          inherit username;
          inherit inputs;
          hostname = "docker";
          inherit git-email;
        };
      };
    };
    */
  };
}
