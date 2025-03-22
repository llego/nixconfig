{
  inputs,
  username,
  pkgs,
  lib,
  ...
}: {
  system.stateVersion = "24.11";

  imports = [
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.raspberry-pi-nix.nixosModules.sd-image
    ./../modules/core
    ./../modules/optional/wifi-networks.nix
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    chromium
  ];

  services.cage = {
    enable = true;
    user = username;
    program = "${pkgs.chromium}/bin/chromium --app=http://192.168.1.103:8123/lovelace-wallmount/default_view --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized";
  };

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "24.11";

    imports = [
    ];
  };

  # Thunderbolt
  # services.hardware.bolt.enable = true;

  raspberry-pi-nix.board = "bcm2712";
  raspberry-pi-nix.libcamera-overlay = {
    enable = false; # set to false (enabled by default)
  };
  hardware = {
    raspberry-pi = {
      config = {
        all = {
          base-dt-params = {
            BOOT_UART = {
              value = 1;
              enable = true;
            };
            uart_2ndstage = {
              value = 1;
              enable = true;
            };
          };
          dt-overlays = {
            disable-bt = {
              enable = false;
              params = {};
            };
          };
        };
      };
    };
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
