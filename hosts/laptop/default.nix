{
  config,
  lib,
  pkgs,
  modulesPath,
  username,
  inputs,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    ./../../modules/core
    ./../../modules/apps.nix
    ./../../modules/desktop-environment.nix
    ./../../modules/printer.nix
    ./../../modules/wifi-networks.nix
    ./../../modules/downloaders.nix
    # inputs.ruuvi.nixosModules.default

    # hardware-configuration.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Bootloader
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth.enable = true;
    # binfmt.emulatedSystems = ["aarch64-linux"]; # Needed to create ISO image for rpi5
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire
  #services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Thunderbolt
  services.hardware.bolt.enable = true;

  # Battery power information
  services.upower.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # SSD optimization - weekly TRIM
  services.fstrim.enable = true;

  # Reduce systemd journal writes
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxRetentionSec=7day
  '';

  # Prevent system freeze when running out of memory
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5; # Kill processes when <5% RAM free
    freeSwapThreshold = 10; # Kill processes when <10% swap free
    enableNotifications = true;
  };

  # Memory management tuning
  boot.kernel.sysctl = {
    "vm.swappiness" = 80; # Use swap proactively to prevent sudden OOM
  };

  fileSystems."/mnt/truenas-docker/data" = {
    device = "truenas.home:/mnt/illby/docker/data";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=300"
      "noatime"
      "nfsvers=4.0"
    ];
  };

  fileSystems."/mnt/truenas-docker/stacks" = {
    device = "truenas.home:/mnt/illby/docker/stacks";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=300"
      "noatime"
      "nfsvers=4.0"
    ];
  };

  # Hardware acceleration (VAAPI)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  #######
  # hardware-configuration.nix
  #######
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/29aed872-9471-4d06-b42a-f6273a892c01";
    fsType = "ext4";
    options = ["noatime"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2BDF-106D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Swap file backup for when zram fills up
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192; # 8GB
    }
  ];

  # Zram compressed swap (primary)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; # With 2-3x compression = 200-300% effective
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Kanshi display configuration (laptop-specific)
  systemd.tmpfiles.rules = [
    "L+ /home/${username}/.config/kanshi/config - - - - ${pkgs.writeText "kanshi-config" ''
      profile undocked {
        output eDP-1 enable scale 2.0
      }

      profile home_office_1 {
        output DP-1 enable mode 3840x2160 scale 1.6
        output eDP-1 disable
      }

      profile home_office_2 {
        output DP-2 enable mode 3840x2160 scale 1.6
        output eDP-1 disable
      }
    ''}"
  ];
}
