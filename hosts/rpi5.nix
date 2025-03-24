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
    ./../modules/optional/ruuvi
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    chromium
    bluez5-experimental
    bluez-tools
    bluez-alsa
    bluetuith
    docker-compose
  ];

  services.cage = {
    enable = true;
    user = username;
    program = "${pkgs.chromium}/bin/chromium --app=http://homeassistant.home:8123/lovelace-wallmount/default_view --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized";
  };

  services.unclutter.enable = true;

  systemd.user.services.scalekiosk = {
    description = "Scale screen to 1.5";
    script = ''
      sleep 8
      WAYLAND_DISPLAY="wayland-0" XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.wlr-randr}/bin/wlr-randr --output "HDMI-A-2" --scale 1.5
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

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = ["docker"];

  #######
  # Home Manager
  #######
  home-manager.users.${username} = {
    home.stateVersion = "24.11";

    imports = [
    ];
  };

  /*
  services.wyoming.satellite = {
    enable = true;
    name = "Kökets Wyoming Satellite";
    user = username;
    uri = "tcp://0.0.0.0:10700";
    sounds.awake = builtins.fetchurl {
      url = "https://github.com/rhasspy/wyoming-satellite/raw/master/sounds/awake.wav";
      sha256 = "6b25dd2abaf7537865222ca9fd6e14fbf723458526fb79bbe29d8261d1320724";
    };
    sounds.done = builtins.fetchurl {
      url = "https://github.com/rhasspy/wyoming-satellite/raw/master/sounds/done.wav";
      sha256 = "bc5c914bfa860a77fa9d88ac2d96601adfede578cf146637ec98b5688911a951";
    };
    extraArgs = [
      "--debug"
      "--wake-word-name=ok_nabu"
      "--wake-uri=tcp://127.0.0.1:10400"
      "--name 'Kökets Wyoming Satellite'"
      "--mic-command 'arecord -D plughw:CARD=ArrayUAC10,DEV=0 -r 16000 -c 1 -f S16_LE -t raw'"
      "--snd-command 'aplay -D sysdefault:CARD=vc4hdmi0 -r 22050 -c 1 -f S16_LE -t raw'"
      "--wake-uri 'tcp://127.0.0.1:10400'"
      "--wake-word-name 'ok_nabu'"
      "--event-uri 'tcp://127.0.0.1:10500'"
      "--timer-finished-wav /home/pi/wyoming-satellite/sounds/timer_finished.wav"
      "--vad-threshold=0.5"
    ];
  };

  services.wyoming.openwakeword = {
    enable = true;
    preloadModels = [
      "ok_nabu"
    ];
    uri = "tcp://0.0.0:10400";
    extraArgs = ["--debug"];
  };
  */

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
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    package = pkgs.bluez5-experimental;
    settings.Policy.AutoEnable = "true";
    settings.General.Enable = "Source,Sink,Media,Socket";
  };
}
