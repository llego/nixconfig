{
  config,
  lib,
  pkgs,
  modulesPath,
  username,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    ./../modules/core
    ./../modules/optional/stylix
    ./../modules/optional/desktop-apps.nix
    ./../modules/optional/docker.nix
    ./../modules/optional/niri-config.nix
    ./../modules/optional/printer.nix
    ./../modules/optional/wifi-networks.nix
    ./../modules/optional/vpn.nix
    #./../modules/optional/ruuvi

    # hardware-configuration.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "24.05";

    imports = [
      # tidal-dl, svtplay-dl, yle-dl, bandcamp collection downloader
      ./../modules/optional/home-manager/downloaders
      ./../modules/optional/home-manager/ai.nix
    ];

    # Kanshi display settings for laptop display and external display
    services.kanshi = {
      enable = true;
      systemdTarget = "graphical-session.target";

      settings = [
        {
          profile.name = "undocked";
          profile.outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              scale = 2.0;
            }
          ];
        }
        {
          profile.name = "home_office_1";
          profile.outputs = [
            {
              criteria = "DP-1";
              status = "enable";
              mode = "3840x2160";
              scale = 1.6;
            }
            {
              criteria = "eDP-1";
              status = "disable";
            }
          ];
        }
        {
          profile.name = "home_office_2";
          profile.outputs = [
            {
              criteria = "DP-2";
              status = "enable";
              mode = "3840x2160";
              scale = 1.6;
            }
            {
              criteria = "eDP-1";
              status = "disable";
            }
          ];
        }
      ];
    };
  };

  # Bootloader
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth.enable = true;
    binfmt.emulatedSystems = ["aarch64-linux"]; # Needed to create ISO image for rpi5
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
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

  # Hardware acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
  };
  hardware.graphics = {
    # hardware.graphics on unstable
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {LIBVA_DRIVER_NAME = "iHD";}; # Force intel-media-driver

  #######
  # hardware-configuration.nix
  #######
  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod"];
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
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
