{
  description = "llego's nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    bandsnatch.url = "github:ovyerus/bandsnatch";
    bandsnatch.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = {
    self,
    nixpkgs,
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
