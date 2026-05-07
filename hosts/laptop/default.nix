{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  username,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
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

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  hardware = {
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Hardware acceleration (VAAPI)
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };
  };

  security.rtkit.enable = true;

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    # Thunderbolt
    hardware.bolt.enable = true;

    # Battery power information
    upower.enable = true;

    # Firmware updates
    fwupd.enable = true;

    # SSD optimization - weekly TRIM
    fstrim.enable = true;

    # Reduce systemd journal writes
    journald.extraConfig = ''
      SystemMaxUse=100M
      MaxRetentionSec=7day
    '';

    # Prevent system freeze when running out of memory
    earlyoom = {
      enable = true;
      freeMemThreshold = 5; # Kill processes when <5% RAM free
      freeSwapThreshold = 10; # Kill processes when <10% swap free
      enableNotifications = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/crisuflix-docker 0755 root root -"
    "d /mnt/crisuflix-docker/data 0755 root root -"
    "d /mnt/crisuflix-docker/stacks 0755 root root -"
  ];
  fileSystems."/mnt/crisuflix-docker/data" = {
    device = "crisuflix.home:/mnt/illby/docker/data";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=300"
      "noatime"
      "nfsvers=4.0"
    ];
  };

  fileSystems."/mnt/crisuflix-docker/stacks" = {
    device = "crisuflix.home:/mnt/illby/docker/stacks";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=300"
      "noatime"
      "nfsvers=4.0"
    ];
  };

  boot = {
    # Bootloader
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    plymouth.enable = true;

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [];
    };
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    # Memory management tuning
    kernel.sysctl = {
      "vm.swappiness" = 80; # Use swap proactively to prevent sudden OOM
    };
  };

  # fileSystems for / and /boot are managed by disko (disk-config.nix)

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

  systemd.user.services.kanshi = {
    enable = true;
    description = "Kanshi display auto-configuration";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi -c /home/${username}/.config/kanshi/config";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
