{
  config,
  lib,
  pkgs,
  ...
}: let
  net = config.networkVars;
in {
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
    settings = {
      reflector.enable-reflector = false;
      publish = {
        "disable-publishing" = false;
        publish-addresses = true;
        publish-workstation = true;
      };
      server.allow-interfaces = ["br0" "br1"];
    };
  };
}
