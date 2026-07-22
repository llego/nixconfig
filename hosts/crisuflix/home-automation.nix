{
  config,
  lib,
  ...
}: let
  net = config.networkVars;
in {
  # Home Assistant OCI Container (Docker backend)
  virtualisation.oci-containers = {
    backend = "docker";
    containers.homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      volumes = [
        "/mnt/illby/appstorage/homeassistant:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "Europe/Helsinki";
      };
      extraOptions = [
        "--network=host"
        "--device=/dev/ttyUSB0:/dev/ttyUSB0"
      ];
    };
  };

  # Music Assistant
  services.music-assistant = {
    enable = true;
    providers = [
      "chromecast"
      "hass"
      "jellyfin"
      "musiccast"
      "sendspin"
      "sonos" # required by musiccast/provider.py (imports sonos.helpers which needs aiosonos)
      "tidal"
    ];
  };

  # Store MA data on illby ZFS dataset instead of the boot drive.
  # BindPaths overlays the illby dataset onto the StateDirectory before service start.
  systemd.services.music-assistant.serviceConfig.BindPaths = [
    "/mnt/illby/appstorage/music-assistant:/var/lib/music-assistant"
  ];

  # Smart Fades uses librosa -> numba -> llvmlite (LLVM JIT), which requires
  # allocating W+X memory pages. MemoryDenyWriteExecute=yes (set by systemd
  # hardening defaults) blocks this with EPERM. Same fix applied to PostgreSQL
  # JIT in nixpkgs (nixpkgs PR #344925).
  systemd.services.music-assistant.serviceConfig.MemoryDenyWriteExecute = lib.mkForce false;

  networking.firewall = {
    # Allow Yamaha MusicCast to send UDP push events (position updates, state
    # changes) back to Music Assistant on its ephemeral UDP port. The Yamaha
    # sends these as unsolicited packets which are otherwise blocked by the
    # stateful firewall. Use iptables syntax because nftables extraInputRules is
    # ignored while Docker uses iptables.
    extraCommands = ''
      iptables -A nixos-fw -p udp -s 192.168.1.247 -j nixos-fw-accept
    '';
    extraStopCommands = ''
      iptables -D nixos-fw -p udp -s 192.168.1.247 -j nixos-fw-accept 2>/dev/null || true
    '';

    allowedTCPPorts = [
      net.crisuflix.musicAssistant.uiPort # Music Assistant (Web UI)
      net.crisuflix.musicAssistant.streamPort # Music Assistant (Stream Server)
      net.crisuflix.homeAssistant.port # Home Assistant
      net.crisuflix.mosquitto.port # MQTT (Mosquitto)
    ];
  };

  # ESPHome dashboard (native NixOS service)
  services.esphome = {
    enable = true;
    address = "0.0.0.0";
    port = 6052;
    openFirewall = true;
    usePing = true;
  };

  # Keep ESPHome state on dedicated ZFS dataset.
  systemd.services.esphome = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "apps";
      Group = lib.mkForce "apps";
      BindPaths = [
        "/mnt/illby/appstorage/esphome:/var/lib/esphome"
      ];
      EnvironmentFile = config.age.secrets.esphome-dashboard-env.path;
    };
  };

  # Native MQTT broker with authentication.
  services.mosquitto = {
    enable = true;
    persistence = true;
    dataDir = "/mnt/illby/appstorage/mosquitto";
    logDest = ["syslog"];
    listeners = [
      {
        port = 1883;
        settings.allow_anonymous = false;
        users.mqtt_user = {
          acl = ["readwrite #"];
          passwordFile = config.age.secrets.mosquitto-mqtt-user-password.path;
        };
      }
    ];
  };

  # Avahi for mDNS/Zeroconf (Chromecast discovery)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    reflector = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    allowInterfaces = ["br0" "br1"];
  };

  local.homepageServices = {
    "Home automation" = [
      {
        homeassistant = {
          href = "https://ha.cri.su";
          icon = "home-assistant";
          description = "cri.su";
          siteMonitor = "http://192.168.1.101:${toString net.crisuflix.homeAssistant.port}";
        };
      }
      {
        esphome = {
          href = "https://esphome.llego.me";
          icon = "esphome";
          description = "llego.me";
          siteMonitor = "http://192.168.1.101:6052";
        };
      }
    ];

    Media = [
      {
        music-assistant = {
          href = "https://ma.cri.su";
          icon = "music-assistant";
          description = "cri.su";
          siteMonitor = "http://192.168.1.101:${toString net.crisuflix.musicAssistant.uiPort}";
        };
      }
    ];
  };
}
