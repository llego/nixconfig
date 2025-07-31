{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    system-config-printer
  ];

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Comment this block to avoid error message on rebuild if printer is not connected
  /*
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
  */
  # Enable autodiscovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
