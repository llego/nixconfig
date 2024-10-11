{
  description = "NixOS and home-manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    bandsnatch.url = "github:ovyerus/bandsnatch";
    bandsnatch.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      host = "laptop";
      username = "llego";
      git-email = "github.login@cri.su";
    in {
   
      # NixOS configurations
      nixosConfigurations = {
        "${host}" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit system;
            inherit inputs;
            inherit username;
            inherit host;
          };
          modules = [ 
            ./hosts/${host}/config.nix
            inputs.stylix.nixosModules.stylix
            inputs.niri.nixosModules.niri
            home-manager.nixosModules.home-manager {
              home-manager.extraSpecialArgs = {
                inherit username;
                inherit inputs;
                inherit host;
                inherit git-email;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.${username} = import ./hosts/${host}/home.nix;   
            }
          ];
        };
      };

      # home-manager configurations
      homeConfigurations = {
        "${username}@docker" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./hosts/jail-docker/home.nix ];
          extraSpecialArgs = { 
            inherit username;
            inherit inputs;
            host = "docker";
            inherit git-email;
          };
        };
      };
      
  };
}
