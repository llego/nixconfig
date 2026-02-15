{
  description = "llego's nix config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org?priority=2"
      # "https://cuda-maintainers.cachix.org?priority=1"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      #"cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

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
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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

      nixvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixvm.nix
        ];
        specialArgs = {
          inherit inputs;
          inherit username;
          hostname = "nixvm";
        };
      };

      # nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage' --system aarch64-linux --accept-flake-config
      # zstd -dc ..linux.img.zst | sudo dd of=/dev/sdX bs=4M status=progress oflag=sync
      # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
      # sudo nixos-rebuild boot --flake .#rpi5 --target-host llego@rpi5.home --accept-flake-config --ask-sudo-password
      # script -q -c "nix --extra-experimental-features 'nix-command flakes' build --print-out-paths '.#nixosConfigurations.rpi5.config.system.build.toplevel' --no-link --accept-flake-config" /dev/null

      # From local machine you can run:
      # nixos-rebuild boot --flake .#rpi5 --build-host=llego@nixvm.iot --target-host llego@rpi5.home --accept-flake-config
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
    };
  };
}
