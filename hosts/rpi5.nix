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
  home-manager.users.${username}.home.stateVersion = "24.11";

  imports = [
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.raspberry-pi-nix.nixosModules.sd-image
    inputs.home-manager.nixosModules.home-manager
    ./../modules/core
    ./../modules/optional/wifi-networks.nix
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    chromium
    python3
    alsa-utils
    wyoming-satellite
    wyoming-openwakeword
    #squeekboard
  ];

  services.cage = {
    enable = true;
    user = username;
    program = "${pkgs.chromium}/bin/chromium --app=http://homeassistant.home:8123/lovelace-wallmount/default_view --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized";
    #program = "/etc/start-kiosk.sh";
  };

/*
            # Write wrapper script
            environment.etc."start-kiosk.sh".text = ''
              #!/bin/sh
              
              export XDG_RUNTIME_DIR=/run/user/$(id -u ${username})
              export WAYLAND_DISPLAY="wayland-0"
              ${pkgs.squeekboard}/bin/squeekboard &
              sleep 1
              exec ${pkgs.chromium}/bin/chromium --app=http://homeassistant.home:8123/lovelace-wallmount/default_view --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized
            '';
*/

  systemd.user.services.scalekiosk = {
    description = "Scale screen to 1.5";
    script = ''
      sleep 8
      export XDG_RUNTIME_DIR=/run/user/$(id -u ${username})
      export WAYLAND_DISPLAY="wayland-0"
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

  services.wyoming.openwakeword = {
    enable = true;
    preloadModels = [
      "ok_nabu"
    ];
    uri = "tcp://0.0.0.0:10400";
    extraArgs = ["--debug"];
  };


/*
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    systemd.user.services.wyoming-satellite = {
      Install = {
        WantedBy = ["multi-user.target"];
      };
      Unit = {
        Description = "Kökets Wyoming Satellite";
        PartOf = "graphical-session.target";
        After = "network.target";
        Requisite = "graphical-session.target";
      };
      Service = {
        ExecStart = ''
          ${pkgs.python3}/bin/python3.12 ${pkgs.wyoming-satellite}/bin/.wyoming-satellite-wrapped \
            --uri tcp://0.0.0.0:10700 \
            --debug \
            --awake-wav ${soundAwake} \
            --done-wav ${soundDone} \
            --wake-word-name ok_nabu \
            --name 'Kökets Wyoming Satellite' \
            --mic-command '${pkgs.alsa-utils}/bin/arecord -D sysdefault:CARD=ArrayUAC10 -r 16000 -c 1 -f S16_LE -t raw' \
            --snd-command '${pkgs.pipewire}/bin/pw-play --target hdmi:CARD=vc4hdmi1,DEV=0 -' \
            --wake-uri tcp://127.0.0.1:10400
        '';
        Restart = "always";
      };
    };
  };
*/


  systemd.services.wyoming-satellite = {
    description = "Kökets Wyoming Satellite";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      User = "wyoming";
      ExecStart = ''
        ${pkgs.python3}/bin/python3.12 ${pkgs.wyoming-satellite}/bin/.wyoming-satellite-wrapped \
          --uri tcp://0.0.0.0:10700 \
          --debug \
          --awake-wav ${soundAwake} \
          --done-wav ${soundDone} \
          --wake-word-name ok_nabu \
          --name 'Kökets Wyoming Satellite' \
          --mic-command '${pkgs.alsa-utils}/bin/arecord -D sysdefault:CARD=ArrayUAC10 -r 16000 -c 1 -t raw' \
          --snd-command '${pkgs.alsa-utils}/bin/aplay -D plughw:CARD=vc4hdmi1,DEV=0 -r 48000 -c 1 -t raw' \
          --wake-uri tcp://127.0.0.1:10400
      '';
      Restart = "always";
    };
    path = with pkgs; [alsa-utils python3]; # Ensures `arecord`, `aplay`, etc. are in PATH
  };

  #          --mic-command '${pkgs.alsa-utils}/bin/arecord -D plughw:2,0 -r 16000 -c 1 -f S16_LE -t raw' \
  #          --snd-command '${pkgs.alsa-utils}/bin/aplay -D plughw:1,0 -r 22050 -c 1 -f S16_LE -t raw' \
  #          --snd-command '${pkgs.alsa-utils}/bin/aplay -D plughw:CARD=vc4hdmi1,DEV=0 -r 48000 -c 1 -f S16_LE -t raw' \
  #          --awake-wav ${soundAwake} \
  #          --done-wav ${soundDone} \
  #          --event-uri tcp://127.0.0.1:10500
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
      "--snd-command 'aplay -D sysdefault:CARD=vc4hdmi1 -r 22050 -c 1 -f S16_LE -t raw'"
      "--wake-word-name 'ok_nabu'"
      "--event-uri 'tcp://127.0.0.1:10500'"
    ];
  };
*/

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.userServices = true;
  };

  networking.firewall.allowedTCPPorts = [10700];
  networking.firewall.allowedUDPPorts = [5353]; # mDNS

  users.users.wyoming = {
    isSystemUser = true;
    group = "audio";
  };


  # Optional but recommended: give applications real-time audio capabilities
  security.rtkit.enable = true;

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
