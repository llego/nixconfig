{
  config,
  lib,
  pkgs,
  ...
}: let
  net = config.networkVars;
  homeAssistantConfiguration = pkgs.writeText "home-assistant-configuration.yaml" ''
    # Managed by nixconfig. Mutable Home Assistant config lives in the included files.

    default_config:

    intent:

    frontend:
      themes: !include_dir_merge_named themes

    homeassistant:
      customize: !include customizations.yaml

      auth_providers:
        - type: trusted_networks
          trusted_networks:
            - 192.168.1.0/24
            - 100.64.0.5/32
            - fd00::/8
          trusted_users:
            100.64.0.5: 340b71d871e7480f8f454163a14bd471
          allow_bypass_login: true
        - type: homeassistant

    # Keep UI-managed and app-managed config writable under /config.
    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
    sensor: !include sensors.yaml
    media_player: !include universal_media_player.yaml
    influxdb: !include influxdb.yaml
    template: !include templates.yaml

    zha:
      zigpy_config:
        ota:
          otau_directory: /config/zigpy_ota
          extra_providers:
            - type: ikea
            - type: salus
  '';
in {
  # Home Assistant OCI Container (Docker backend)
  virtualisation.oci-containers = {
    backend = "docker";
    containers.homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      volumes = [
        "/mnt/illby/appstorage/homeassistant:/config"
        # Docker creates an empty lower-layer placeholder at the host path;
        # the container still reads this read-only Nix store file.
        "${homeAssistantConfiguration}:/config/configuration.yaml:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "Europe/Helsinki";
      };
      extraOptions = [
        "--network=host"
        "--device=/dev/ttyUSB0:/dev/ttyUSB0"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };
  };

  # Music Assistant runs in /mnt/illby/docker/stacks/music-assistant with
  # host networking and /mnt/illby/appstorage/music-assistant mounted at /data.
  # Its host firewall rules remain here; ma.cri.su is routed via traefik-kop.

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

  # ESPHome Device Builder dashboard (native NixOS service)
  services.esphome = {
    enable = true;
    address = "0.0.0.0";
    port = net.crisuflix.esphome.uiPort;
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
      ExecStart = lib.mkForce "${pkgs.esphome-device-builder}/bin/esphome-device-builder --host 0.0.0.0 --port ${toString net.crisuflix.esphome.uiPort} /var/lib/esphome";
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
  # reflector disabled to avoid duplicate mDNS paths with UniFi mDNS Proxy
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    reflector = false;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    allowInterfaces = ["br0" "br1"];
  };
}
