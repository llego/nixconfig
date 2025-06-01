{
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
    inputs.home-manager.nixosModules.home-manager
    ./../modules/core
    ./../modules/optional/gaming.nix
    ./../modules/optional/stylix
    ./../modules/optional/desktop-apps.nix
    ./../modules/optional/niri-config.nix
    ./../modules/optional/printer.nix
    ./../modules/optional/wifi-networks.nix
    ./../modules/optional/vpn.nix

    # hardware-configuration.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "24.11";

    imports = [];

    programs.niri.settings.outputs."DP-3" = {
      enable = true;
      scale = 1.6;
      mode = {
        width = 5120;
        height = 2160;
        refresh = 60.0;
      };
      variable-refresh-rate = false;
    };
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
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Force Feed Back for Moza wheel and driver for wifi usb dongle
  boot.extraModulePackages = with config.boot.kernelPackages; [universal-pidff];
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyACM*", ATTRS{idVendor}=="346e", ACTION=="add", MODE="0666", TAG+="uaccess"
  '';

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
