{
  description = "llego's nix config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org?priority=2"
      #"https://cuda-maintainers.cachix.org?priority=1"
      "https://niri.cachix.org?priority=1"
      "https://llego.cachix.org?priority=1"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      #"cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "llego.cachix.org-1:WzO82OCKQr+mNapPewBwEeN5Ui5vPjduTIYfrD0YFwQ="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    #stylix.url = "github:danth/stylix/release-25.11";
    #niri.url = "github:sodiboo/niri-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    bandsnatch.url = "github:ovyerus/bandsnatch";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
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

      # nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage' --system aarch64-linux --accept-flake-config
      # zstd -dc ..linux.img.zst | sudo dd of=/dev/sdX bs=4M status=progress oflag=sync
      # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
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
