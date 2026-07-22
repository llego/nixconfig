# Network configuration variables shared across hosts
# Centralizes IP addresses and ports for the homelab infrastructure
{lib, ...}: {
  options.networkVars = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "cri.su";
      description = "Domain for all services";
    };

    # IP Addresses by host
    hosts = {
      vps = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.4";
        description = "VPS stable tailnet IP";
      };

      crisuflix = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.1";
        description = "Crisuflix stable tailnet IP";
      };

      loopback = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Loopback address for native services (Authelia, Gotify, etc.)";
      };
    };

    # VPS Service Ports
    vps = {
      authelia.port = lib.mkOption {
        type = lib.types.port;
        default = 9092;
        description = "Authelia service port for cri.su domain";
      };

      gotify.port = lib.mkOption {
        type = lib.types.port;
        default = 8079;
        description = "Gotify service port";
      };

      uptimeKuma.port = lib.mkOption {
        type = lib.types.port;
        default = 3001;
        description = "Uptime Kuma service port";
      };

      redis.port = lib.mkOption {
        type = lib.types.port;
        default = 6379;
        description = "Redis port for traefik-kop";
      };

      website.port = lib.mkOption {
        type = lib.types.port;
        default = 8082;
        description = "Static website server port";
      };

      headscale.port = lib.mkOption {
        type = lib.types.port;
        default = 8085;
        description = "Headscale/tailscale service port";
      };

      headplane.port = lib.mkOption {
        type = lib.types.port;
        default = 8086;
        description = "Headplane service port";
      };

      traefik.port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Traefik API/dashboard port";
      };
    };

    # Crisuflix Service Ports
    crisuflix = {
      homeAssistant.port = lib.mkOption {
        type = lib.types.port;
        default = 8123;
        description = "Home Assistant service port";
      };

      musicAssistant.uiPort = lib.mkOption {
        type = lib.types.port;
        default = 8095;
        description = "Music Assistant Web UI port";
      };

      musicAssistant.streamPort = lib.mkOption {
        type = lib.types.port;
        default = 8098;
        description = "Music Assistant Stream Server port";
      };

      jellyfin.port = lib.mkOption {
        type = lib.types.port;
        default = 8096;
        description = "Jellyfin media server port";
      };

      mosquitto.port = lib.mkOption {
        type = lib.types.port;
        default = 1883;
        description = "Mosquitto MQTT broker port";
      };

      nut.port = lib.mkOption {
        type = lib.types.port;
        default = 3493;
        description = "NUT (UPS monitoring) port";
      };

      glances.port = lib.mkOption {
        type = lib.types.port;
        default = 61208;
        description = "Glances monitoring web UI port";
      };

      opencloud.port = lib.mkOption {
        type = lib.types.port;
        default = 9200;
        description = "OpenCloud proxy port";
      };

      collabora.port = lib.mkOption {
        type = lib.types.port;
        default = 9980;
        description = "Collabora Online (coolwsd) port";
      };

      homepage.port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Homepage dashboard port";
      };

      signalCli.port = lib.mkOption {
        type = lib.types.port;
        default = 8089;
        description = "signal-cli HTTP daemon port (loopback only, used by hermes-agent Signal adapter)";
      };
    };

    # NFS Ports
    nfs = {
      rpcbind.port = lib.mkOption {
        type = lib.types.port;
        default = 111;
        description = "NFS rpcbind port";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 2049;
        description = "NFS server port";
      };

      mountd.port = lib.mkOption {
        type = lib.types.port;
        default = 20048;
        description = "NFS mountd port";
      };
    };

    # Beszel Hub URL
    beszel = {
      hubUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://crisuflix.tailnet.cri.su:8090";
        description = "Beszel hub URL for agents to connect to";
      };
    };
  };
}
