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

 outputs = { self, nixpkgs, stylix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
   
      # default home-manager configuration for laptop
      homeConfigurations.default = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hosts/default/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };
        
      # home-manager configuration for jail on truenas
      homeConfigurations."jail" = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hosts/jail/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };

      # NixOS configuration
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs;};
        modules = [ stylix.nixosModules.stylix ./hosts/default/configuration.nix ];
      };

    };
}
