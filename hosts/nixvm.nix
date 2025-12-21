{ config, lib, pkgs, modulesPath, username,... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ./../modules/core
    ];

  system.stateVersion = "25.11";

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "25.11";
    imports = [
      ./../modules/optional/home-manager/downloaders
      #./../modules/optional/home-manager/swayidle.nix
      # ./../modules/optional/home-manager/kanshi.nix
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixvm"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  boot.initrd.availableKernelModules = [ "ata_piix" "xhci_pci" "ahci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/c9f17c7f-4952-4b84-bd1e-9dd374dac51c";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/09EB-5EE9";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/6b0bd8c6-4b5e-4a16-b2b4-5712a77dc4a4"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
