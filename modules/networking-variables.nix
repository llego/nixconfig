# Network configuration variables shared across hosts
# Centralizes IP addresses and ports for the homelab infrastructure
{lib, ...}: {
  options.networkVars = {
    # IP Addresses
    vpsIP = lib.mkOption {
      type = lib.types.str;
      default = "100.78.37.16";
      description = "VPS IP address for christiansandberg server";
    };

    crisuflixIP = lib.mkOption {
      type = lib.types.str;
      default = "100.123.67.48";
      description = "Tailscale IP address for crisuflix (traefik-kop source)";
    };

    loopbackIP = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Loopback address for native services (Authelia, Gotify, etc.)";
    };

    # VPS Service Ports
    autheliaCriSuPort = lib.mkOption {
      type = lib.types.port;
      default = 9092;
      description = "Authelia service port for cri.su domain";
    };

    gotifyPort = lib.mkOption {
      type = lib.types.port;
      default = 8079;
      description = "Gotify service port";
    };

    uptimeKumaPort = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "Uptime Kuma service port";
    };

    redisPort = lib.mkOption {
      type = lib.types.port;
      default = 6379;
      description = "Redis port for traefik-kop";
    };

    websitePort = lib.mkOption {
      type = lib.types.port;
      default = 8082;
      description = "Static website server port";
    };

    homeassistantPort = lib.mkOption {
      type = lib.types.port;
      default = 8123;
      description = "Home Assistant service port";
    };

    # frigatePort = lib.mkOption {
    #   type = lib.types.port;
    #   default = 5000;
    #   description = "Frigate NVR service port";
    # };

    # Crisuflix Service Ports
    musicAssistantUIPort = lib.mkOption {
      type = lib.types.port;
      default = 8095;
      description = "Music Assistant Web UI port";
    };

    musicAssistantStreamPort = lib.mkOption {
      type = lib.types.port;
      default = 8098;
      description = "Music Assistant Stream Server port";
    };

    jellyfinPort = lib.mkOption {
      type = lib.types.port;
      default = 8096;
      description = "Jellyfin media server port";
    };

    mosquittoPort = lib.mkOption {
      type = lib.types.port;
      default = 1883;
      description = "Mosquitto MQTT broker port";
    };

    nutPort = lib.mkOption {
      type = lib.types.port;
      default = 3493;
      description = "NUT (UPS monitoring) port";
    };

    # NFS Ports
    nfsRpcbindPort = lib.mkOption {
      type = lib.types.port;
      default = 111;
      description = "NFS rpcbind port";
    };

    nfsPort = lib.mkOption {
      type = lib.types.port;
      default = 2049;
      description = "NFS server port";
    };

    nfsMountdPort = lib.mkOption {
      type = lib.types.port;
      default = 20048;
      description = "NFS mountd port";
    };

    glancesPort = lib.mkOption {
      type = lib.types.port;
      default = 61208;
      description = "Glances monitoring web UI port";
    };
  };
}
