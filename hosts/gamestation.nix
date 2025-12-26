{
  pkgs,
  username,
  hostname,
  config,
  modulesPath,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "24.11";

  imports = [
    ./../modules/core
    ./../modules/optional/apps.nix
    ./../modules/optional/niri-config.nix
    ./../modules/optional/printer.nix
    ./../modules/optional/wifi-networks.nix
    ./../modules/optional/development.nix

    # hardware-configuration.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "24.11";

    imports = [
      ./../modules/optional/home-manager/swayidle.nix
    ];

    # programs.niri.settings.outputs."DP-3" = {
    #   enable = true;
    #   scale = 1.6;
    #   mode = {
    #     width = 5120;
    #     height = 2160;
    #     refresh = 60.0;
    #   };
    #   variable-refresh-rate = false;
    # };
  };

  # Game related packages
  environment.systemPackages = with pkgs; [
    mangohud
    protonup
    lutris
    xwayland-run
    mesa-demos
    boxflat
  ];

  # Steam
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  programs.gamescope.capSysNice = true;

  # Force Feed Back for Moza wheel and driver for wifi usb dongle
  boot.kernelPackages = pkgs.linuxPackages_latest; # Use the latest kernel for native FFB
  boot.extraModulePackages = with config.boot.kernelPackages; [universal-pidff];
  services.udev.extraRules = ''
    # Moza Wheel Base
    KERNEL=="ttyACM*", ATTRS{idVendor}=="1af3", MODE="0666", GROUP="dialout"
    # Moza Pedals / Accessories
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1af3", MODE="0666", GROUP="dialout"
  '';

  programs.niri.enable = true;

  # Ensure apps use the GPU correctly
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Required for flickering-free Electron apps (Discord, VS Code) in 2025
    NIXOS_OZONE_WL = "1";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam and many Wine games
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable this option to support certain USB WLAN and WWAN adapters.
  # These network adapters initial present themselves as Flash Drives containing their drivers.
  # This option enables automatic switching to the networking mode.
  hardware.usb-modeswitch.enable = true;

  #######
  # hardware-configuration.nix
  #######
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2cd4578a-252e-4836-93d6-f28aed4eae96";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/22F9-04F0";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp4s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp8s0f3u1u1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp5s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
