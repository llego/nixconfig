# Network configuration for christiansandberg VPS
# Centralizes IP addresses, ports, and domain configuration
{lib, ...}: {
  options.christiansandbergNetwork = {
    tailscaleIP = lib.mkOption {
      type = lib.types.str;
      default = "100.78.37.16";
      description = "Tailscale IP address for christiansandberg";
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

    frigatePort = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      description = "Frigate NVR service port";
    };

    websitePackage = lib.mkOption {
      type = lib.types.package;
      description = "Website files as a nix package";
    };
  };
}
