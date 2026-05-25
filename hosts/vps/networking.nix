# Traefik VPS configuration module
# Provides reverse proxy with Redis for traefik-kop integration
{config, ...}: let
  net = config.networkVars;
in {
  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      # Allow crisuflix (via Tailscale) to reach Redis for traefik-kop
      extraCommands = ''
        iptables -w -I nixos-fw -p tcp -s ${net.hosts.crisuflix} --dport ${toString net.vps.redis.port} -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -w -D nixos-fw -p tcp -s ${net.hosts.crisuflix} --dport ${toString net.vps.redis.port} -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };

  # Cloudflare DDNS for christiansandberg.fi and sandbergs.fi domains (IPv4 only)
  # NOTE: cri.su moved to EuroDNS ddclient
  services.cloudflare-ddns = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-ddns-token.path;
    ip4Domains = ["christiansandberg.fi" "sandbergs.fi" "crisusandberg.fi" "csandberg.fi"];
    ip6Domains = []; # Disable IPv6 DDNS
    proxied = "false";
  };

  # EuroDNS DDNS for cri.su domain
  services.ddclient = {
    enable = true;
    protocol = "dyndns2";
    server = "update.eurodyndns.org";
    username = "eurodns.login@cri.su";
    passwordFile = config.age.secrets.eurodns-cri-su-password.path;
    domains = ["cri.su"];
    ssl = true;
    interval = "5min";
    usev6 = "no"; # Disable IPv6 - VPS lacks connectivity
  };

  # Redis for traefik-kop (crisuflix publishes container routes here)
  services.redis.servers.traefik = {
    enable = true;
    bind = net.hosts.vps;
    port = net.vps.redis.port;
    settings = {
      protected-mode = "no";
    };
  };

  # Ensure Redis waits for network to be online (including Tailscale)
  systemd.services.redis-traefik = {
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target" "tailscaled.service"];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Traefik reverse proxy
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      api = {
        dashboard = true;
        insecure = true;
      };

      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http.tls = {
            certResolver = "myresolver";
            domains = [
              {main = "christiansandberg.fi";}
              {main = "cri.su";}
              {main = "sandbergs.fi";}
              {main = "csandberg.consulting";}
              {main = "crisusandberg.fi";}
              {main = "csandberg.fi";}
              {main = "cloud.cri.su";}
              {main = "office.cri.su";}
            ];
          };
        };
      };

      certificatesResolvers.myresolver.acme = {
        email = "traefik.certs@cri.su";
        storage = "/var/lib/traefik/acme.json";
        httpChallenge.entryPoint = "web";
      };

      providers = {
        redis = {
          endpoints = ["${net.hosts.vps}:${toString net.vps.redis.port}"];
          rootKey = "traefik";
        };
      };

      serversTransport.insecureSkipVerify = true;
    };

    # Dynamic configuration for native services (Authelia, Gotify, Uptime Kuma)
    dynamicConfigOptions = {
      http = {
        routers = {
          authelia-cri-su = {
            rule = "Host(`auth.cri.su`)";
            entryPoints = ["websecure"];
            service = "authelia-cri-su";
            tls.certResolver = "myresolver";
          };
          gotify = {
            rule = "Host(`gotify.cri.su`)";
            entryPoints = ["websecure"];
            service = "gotify";
            tls.certResolver = "myresolver";
          };
          uptime-kuma = {
            rule = "Host(`uptime.cri.su`)";
            entryPoints = ["websecure"];
            service = "uptime-kuma";
            tls.certResolver = "myresolver";
            middlewares = ["authelia-cri-su"];
          };
          website = {
            rule = "Host(`christiansandberg.fi`) || Host(`www.christiansandberg.fi`) || Host(`sandbergs.fi`) || Host(`www.sandbergs.fi`) || Host(`csandberg.consulting`) || Host(`crisusandberg.fi`) || Host(`csandberg.fi`)";
            entryPoints = ["websecure"];
            service = "website";
            tls.certResolver = "myresolver";
          };
          homeassistant = {
            rule = "Host(`ha.cri.su`)";
            entryPoints = ["websecure"];
            service = "homeassistant";
            tls.certResolver = "myresolver";
          };
          glances = {
            rule = "Host(`glances.cri.su`)";
            entryPoints = ["websecure"];
            service = "glances";
            tls.certResolver = "myresolver";
            middlewares = ["authelia-cri-su"];
          };
          homepage = {
            rule = "Host(`cri.su`)";
            entryPoints = ["websecure"];
            service = "homepage";
            tls.certResolver = "myresolver";
            middlewares = ["authelia-cri-su"];
          };
          opencloud = {
            rule = "Host(`cloud.cri.su`)";
            entryPoints = ["websecure"];
            service = "opencloud";
            tls.certResolver = "myresolver";
            # No Authelia — OpenCloud has its own authentication
          };
          collabora = {
            rule = "Host(`office.cri.su`)";
            entryPoints = ["websecure"];
            service = "collabora";
            tls.certResolver = "myresolver";
            # No Authelia — WOPI requests from OpenCloud must pass through unauthenticated
          };
        };

        services = {
          authelia-cri-su.loadBalancer.servers = [
            {
              url = "http://${net.hosts.loopback}:${toString net.vps.authelia.port}";
            }
          ];
          gotify.loadBalancer.servers = [
            {
              url = "http://${net.hosts.loopback}:${toString net.vps.gotify.port}";
            }
          ];
          uptime-kuma.loadBalancer.servers = [
            {
              url = "http://${net.hosts.loopback}:${toString net.vps.uptimeKuma.port}";
            }
          ];
          website.loadBalancer.servers = [
            {
              url = "http://${net.hosts.loopback}:${toString net.vps.website.port}";
            }
          ];
          homepage.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.homepage.port}";
            }
          ];
          homeassistant.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.homeAssistant.port}";
            }
          ];
          glances.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.glances.port}";
            }
          ];
          opencloud.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.opencloud.port}";
            }
          ];
          collabora.loadBalancer = {
            servers = [
              {
                url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.collabora.port}";
              }
            ];
            # Collabora uses WebSockets for real-time editing
            passHostHeader = true;
          };
        };

        middlewares = {
          authelia-cri-su.forwardAuth = {
            address = "http://${net.hosts.loopback}:${toString net.vps.authelia.port}/api/authz/forward-auth?authelia_url=https%3A%2F%2Fauth.cri.su%2F";
            authResponseHeaders = ["Remote-User" "Remote-Groups" "Remote-Email" "Remote-Name"];
            trustForwardHeader = true;
          };
        };
      };
    };
  };
}
