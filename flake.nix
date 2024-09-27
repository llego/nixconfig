{
  description = "NixOS and home-manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    bandsnatch = {
      url = "github:ovyerus/bandsnatch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

 outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
   
      # home-manager configurations
      homeConfigurations = {
        "llego@laptop" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            inputs.stylix.homeManagerModules.stylix 
            ./hosts/default/home.nix 
          ];
          extraSpecialArgs = { inherit inputs; };
        };
#        jail = inputs.home-manager.lib.homeManagerConfiguration {
#          inherit pkgs;
#          modules = [ ./hosts/jail/home.nix ];
#          extraSpecialArgs = { inherit inputs; };
#        };
      };

      # NixOS configurations
      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          modules = [ 
            inputs.stylix.nixosModules.stylix
            ./hosts/default/configuration.nix 
          ];
          specialArgs = { inherit inputs;};
        };
      };

    };
}
