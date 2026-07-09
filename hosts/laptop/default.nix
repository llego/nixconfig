{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./../../modules/core
    ./../../modules/basic-cli.nix
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

  services.tailscale.authKeyFile = config.age.secrets.tailscale-preauth-laptop.path;

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
    "d /mnt/crisuflix-media 0755 root root -"
  ];
  fileSystems."/mnt/crisuflix-docker" = {
    device = "crisuflix.tailnet.cri.su:/mnt/illby/docker";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=300"
      "noatime"
      "nfsvers=4.2"
    ];
  };

  fileSystems."/mnt/crisuflix-media" = {
    device = "crisuflix.tailnet.cri.su:/mnt/veckjarvi/media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=300"
      "noatime"
      "nfsvers=4.2"
    ];
  };

  boot = {
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
      # Laptop has a hardware TPM2 chip but it is not enrolled in LUKS.
      # Disable to prevent initrd TPM2 module errors.
      systemd.tpm2.enable = false;
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
    memoryPercent = 100;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  systemd.user.services.kanshi = let
    kanshiConfig = pkgs.writeText "kanshi-config" ''
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
    '';
  in {
    enable = true;
    description = "Kanshi display auto-configuration";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi -c ${kanshiConfig}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
