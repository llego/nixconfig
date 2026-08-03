{
  description = "llego's nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    album-downloader = {
      url = "path:./pkgs/album-downloader";
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
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem-impure = {
      url = "github:Rexcrazy804/hjem-impure";
      inputs.nixpkgs.follows = "";
      inputs.hjem.follows = "";
    };
    hetzner_ddns = {
      url = "github:filiparag/hetzner_ddns";
      flake = false;
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    christiansandberg-website = {
      url = "git+ssh://git@github.com/llego/christiansandberg.fi.git";
      flake = false;
    };
    headplane = {
      url = "github:tale/headplane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    username = "llego";
    reporoot = ./.;
    dots = reporoot + "/dots";
    commonSpecialArgs = {
      inherit inputs username reporoot dots;
    };
  in {
    nixosConfigurations = {
      # nix build --impure .#nixosConfigurations.laptop-installer.config.system.build.isoImage
      # sudo dd if=result/iso/*.iso of=/dev/sdi bs=4M status=progress oflag=sync
      # (--impure required because SSH keys are read from /home/llego/.ssh/ at build time)
      laptop-installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/installer];
        specialArgs = commonSpecialArgs;
      };

      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/laptop];
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "laptop";
          };
      };

      vps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/vps];
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "vps";
          };
      };

      # nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage' --system aarch64-linux
      # zstd -dc ..linux.img.zst | sudo dd of=/dev/sdX bs=4M status=progress oflag=sync
      # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
      rpi5 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [./hosts/rpi5];
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "rpi5";
          };
      };

      crisuflix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/crisuflix];
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "crisuflix";
            pkgs-unstable = import inputs.nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
      };
    };
  };
}
