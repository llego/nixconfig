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
    ./../../modules/core
    ./../../modules/wifi-networks.nix
    # inputs.ruuvi.nixosModules.default
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    # python3
    cage
    # squeekboard
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

  programs.chromium = {
    enable = true;
    #extensions = [
    #  "cjabmkimbcmhhepelfhjhbhonnapiipj" # simple-virtual-keyboard
    #];
  };

  services.cage = {
    enable = true;
    user = username;
    program = "${pkgs.chromium}/bin/chromium --app=http://homeassistant.home:8123/lovelace-wallmount/default_view --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized";
    #program = "${pkgs.chromium}/bin/chromium --app=https://duckduckgo.com/ --user-data-dir=/home/llego/kiosk-profile-dir --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized";
    #program = "/home/llego/start-kiosk.sh";
    #environment = {
    #WAYLAND_DISPLAY = "wayland-0";
    #};
  };

  systemd.user.services.scalekiosk = {
    description = "Scale screen to 1.5";
    environment = {
      XDG_RUNTIME_DIR = "/run/user/1000";
      WAYLAND_DISPLAY = "wayland-0";
    };
    script = ''
      sleep 8
      ${pkgs.wlr-randr}/bin/wlr-randr --output "HDMI-A-2" --scale 1.5
    '';
    wantedBy = ["basic.target"];
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "* 1 * * *      llego    WAYLAND_DISPLAY='wayland-0' XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.wlr-randr}/bin/wlr-randr --output 'HDMI-A-2' --off"
      "* 6 * * *      llego    WAYLAND_DISPLAY='wayland-0' XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.wlr-randr}/bin/wlr-randr --output 'HDMI-A-2' --on"
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.userServices = true;
  };

  networking.firewall.allowedTCPPorts = [10700];
  networking.firewall.allowedUDPPorts = [5353]; # mDNS

  systemd.timers."nightly-reboot" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "02:00"; # pick your time
      Persistent = true; # reboot after missed time if machine was off
      Unit = "nightly-reboot.service";
    };
  };

  systemd.services."nightly-reboot" = {
    description = "Nightly reboot";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.systemd}/bin/systemctl reboot
    '';
  };

  # Disable bluetoothd so hcitool has raw HCI access for ruuvi-collector
  # raspberry-pi-nix enables bluetooth by default; mkForce overrides it
  hardware.bluetooth = {
    enable = lib.mkForce false;
    powerOnBoot = lib.mkForce false;
  };

  raspberry-pi-nix = {
    board = "bcm2712";
    libcamera-overlay.enable = false; # set to false (enabled by default)
  };

  hardware = {
    enableRedistributableFirmware = true;
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
            vc4-kms-v3d.enable = true;
            # Bluetooth enabled for RuuviCollector
            # disable-bt = {
            #   enable = true;
            #   params = {};
            # };
          };
        };
      };
    };
  };
}
