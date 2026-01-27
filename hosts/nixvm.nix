{
  config,
  lib,
  pkgs,
  modulesPath,
  username,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./../modules/core.nix
    ./../modules/development.nix
  ];

  system.stateVersion = "25.11";

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "25.11";
    imports = [
      ./../modules/home-manager/downloaders
      #./../modules/home-manager/swayidle.nix
      # ./../modules/home-manager/kanshi.nix
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Needed to create ISO image for rpi5
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # With these settings we don't need to add  "--option sandbox false --option filter-syscalls false" when build locally and deploying to rpi5
  nix.settings = {
    sandbox = false;
    filter-syscalls = false;
  };

  networking.hostName = "nixvm"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  boot.initrd.availableKernelModules = ["ata_piix" "xhci_pci" "ahci" "virtio_pci" "sr_mod" "virtio_blk"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/77327aa6-7cc3-4746-8972-7290d9367698";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3892-F27C";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/2ae54f2e-dabc-4507-b8c0-b4a9ec018342";}
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
