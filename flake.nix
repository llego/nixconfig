{
  description = "llego's nix config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    bandsnatch.url = "github:ovyerus/bandsnatch";
    bandsnatch.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    niri.url = "github:sodiboo/niri-flake";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-generators,
    ...
  } @ inputs: let
    #system = "x86_64-linux";
    #pkgs = import nixpkgs {inherit system;};
    username = "llego";
    git-email = "github.login@cri.su";
  in {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./common-modules
          ./hosts/laptop
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit git-email;
          hostname = "laptop";
        };
      };

      gaming = nixpkgs.lib.nixosSystem {
        modules = [
          ./common-modules
          ./hosts/gaming
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit git-email;
          hostname = "gaming";
        };
      };
    };
    packages.x86_64-linux = {
      gaming-iso = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./common-modules
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

    /*
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
