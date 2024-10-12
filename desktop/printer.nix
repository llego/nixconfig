
{ config, pkgs, ... }:
{
  
  # Enable CUPS to print documents
  services.printing.enable = true;

  services.printing.drivers = [ pkgs.cnijfilter_4_00 ];

# Comment this block to avoid error message on rebuild if printer is not connected
#  hardware.printers = {
#    ensurePrinters = [
#      {
#        name = "Canon_MG2400";
#        location = "Home";
#        deviceUri = "usb://Canon/MG2400%20series?serial=2F0738&interface=1";
#        model = "canonmg2400.ppd Canon MG2400 series Ver.4.00";
#        ppdOptions = {
#          PageSize = "A4";
#        };
#      }
#    ];
#  };

}
