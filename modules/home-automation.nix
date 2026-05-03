{
  config,
  lib,
  ...
}: {
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
          passwordFile = config.age.secrets.mosquitto-mqtt-user-password.path;
        };
      }
    ];
  };

  # Avahi for mDNS/Zeroconf (Chromecast discovery)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    allowInterfaces = ["br0" "br1"];
  };
}
