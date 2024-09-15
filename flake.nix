{
  description = "NixOS and home-manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x84_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
    	
    	homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
    		extraSpecialArgs = { inherit inputs; };
    		pkgs = nixpkgs.legacyPackages."x86_64-linux";
    		modules = [ ./hosts/default/home.nix ];
    	};
    	
    	# NixOS configuration
    	nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      	specialArgs = { inherit inputs;};
      	modules = [	./hosts/default/configuration.nix ];
    	};

  	};
}
