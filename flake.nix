{
  description = "llego's nix config";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:nixos/nixpkgs";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    album-downloader = {
      url = "path:./pkgs/album-downloader";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ruuvi = {
      url = "path:./pkgs/RuuviCollector";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

      # nixos-rebuild switch --flake .#christiansandberg --sudo --target-host "llego@christiansandberg.fi"
      christiansandberg = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/christiansandberg.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          hostname = "christiansandberg";
        };
      };

      # nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage' --system aarch64-linux
      # zstd -dc ..linux.img.zst | sudo dd of=/dev/sdX bs=4M status=progress oflag=sync
      # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD

      # To rebuild: nixos-rebuild boot --flake .#rpi5 --target-host llego@rpi5.home --sudo
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

      # nixos-rebuild switch --flake .#crisuflix --target-host "llego@crisuflix.home" --sudo
      crisuflix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/crisuflix.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          hostname = "crisuflix";
        };
      };
    };
  };
}
