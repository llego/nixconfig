{
  inputs,
  username,
  pkgs,
  ...
}: let
  soundAwake = builtins.fetchurl {
    url = "https://github.com/rhasspy/wyoming-satellite/raw/master/sounds/awake.wav";
    sha256 = "6b25dd2abaf7537865222ca9fd6e14fbf723458526fb79bbe29d8261d1320724";
  };

  soundDone = builtins.fetchurl {
    url = "https://github.com/rhasspy/wyoming-satellite/raw/master/sounds/done.wav";
    sha256 = "bc5c914bfa860a77fa9d88ac2d96601adfede578cf146637ec98b5688911a951";
  };
in {
  system.stateVersion = "24.11";

  imports = [
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.raspberry-pi-nix.nixosModules.sd-image
    ./../modules/core.nix
    ./../modules/wifi-networks.nix
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    python3
    cage
    squeekboard
  ];

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

  /*
  # Write wrapper script
  environment.etc."start-kiosk.sh".text = ''
    #!/bin/sh

    ${pkgs.squeekboard}/bin/squeekboard &
    sleep 3
    ${pkgs.chromium}/bin/chromium \
      --app=http://homeassistant.home:8123/lovelace-wallmount/default_view \
      --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland \
      --enable-features=OverlayScrollbar --start-maximized
  '';
  */

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
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:00";   # pick your time
      Persistent = true;      # reboot after missed time if machine was off
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

  # Optional but recommended: give applications real-time audio capabilities
  #  security.rtkit.enable = true;

  #  services.pipewire = {
  #    enable = true;
  #    alsa.enable = true;
  #    alsa.support32Bit = true;
  #    pulse.enable = true;
  #    jack.enable = true;
  #  };

  # Bluetooth
  #hardware.bluetooth = {
  #enable = true;
  #powerOnBoot = true;
  #package = pkgs.bluez5-experimental;
  #settings.Policy.AutoEnable = "true";
  #settings.General.Enable = "Source,Sink,Media,Socket";
  #};

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
            disable-bt = {
              enable = true;
              params = {};
            };
          };
        };
      };
    };
  };
}
