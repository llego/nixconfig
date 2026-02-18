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
    ./../modules/core.nix
    ./../modules/basic-cli.nix
    ./../modules/apps.nix
    ./../modules/desktop-environment.nix
    ./../modules/printer.nix
    ./../modules/wifi-networks.nix
    ./../modules/vpn.nix
    ./../modules/downloaders.nix
    # inputs.ruuvi.nixosModules.default

    # hardware-configuration.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # services.ruuvi-collector = {
  #   enable = true;
  #   influxUrl = "http://192.168.1.101:8086";
  #   influxDatabase = "ruuvi";
  #   tagNames = {
  #     "D4EE9FE30B24" = "Kylskåpet";
  #     "FFE65BB31904" = "Vardagsrummet";
  #   };
  #   filterMode = "named"; # Only collect from named tags
  # };

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

  # Hardware acceleration
  #nixpkgs.config.packageOverrides = pkgs: {
  #  intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
  #};
  hardware.graphics = {
    # hardware.graphics on unstable
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      #libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  }; # Force intel-media-driver

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
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2BDF-106D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
