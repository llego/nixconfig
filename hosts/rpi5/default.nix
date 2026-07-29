{
  inputs,
  username,
  pkgs,
  lib,
  config,
  ...
}: {
  system.stateVersion = "24.11";

  imports = [
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.raspberry-pi-nix.nixosModules.sd-image
    ./../../modules/core
    ./../../modules/wifi-networks.nix
  ];

  services.tailscale = {
    authKeyFile = config.age.secrets.tailscale-preauth-rpi5.path;
    extraSetFlags = [
      "--ssh"
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    wlr-randr
    cage
  ];

  programs.chromium = {
    enable = true;
  };

  services.cage = {
    enable = true;
    user = username;
    program = "${pkgs.chromium}/bin/chromium --app=http://crisuflix.tailnet.cri.su:8123/lovelace-wallmount/default_view --user-data-dir=/home/${username}/kiosk-profile --disk-cache-dir=/tmp/chromium-cache --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized";
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

  systemd.timers."nightly-reboot" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "06:30"; # pick your time
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

  # raspberry-pi-nix enables bluetooth by default; mkForce overrides it.
  hardware.bluetooth = {
    enable = lib.mkForce false;
    powerOnBoot = lib.mkForce false;
  };

  # Use classic initrd — systemd initrd is incompatible with the raspberry-pi-nix
  # kernel build on NixOS 26.05+. The tpm2 fix is no longer needed as a consequence.
  boot.initrd.systemd.enable = false;

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
