{pkgs, ...}: {
  # Enable CUPS to print documents
  services.printing.enable = true;
  #services.printing.drivers = [pkgs.cnijfilter_4_00];

  # Comment this block to avoid error message on rebuild if printer is not connected
  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_Smart_Tank";
        location = "Home";
        deviceUri = "http://192.168.3.125:631/ipp/print";
        model = "drv:///cupsfilters.drv/pwgrast.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
  };

  # Enable autodiscovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # BLuetooth
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
  # https://nixos.wiki/wiki/Thunderbolt
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
}
