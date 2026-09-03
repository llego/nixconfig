# Provides reverse proxy with Redis for traefik-kop integration
{config, ...}: let
  net = config.networkVars;
in {
  # Redis for traefik-kop (crisuflix publishes container routes here)
  services.redis.servers.traefik = {
    enable = true;
    bind = null;
    port = net.vps.redis.port;
    requirePassFile = config.age.secrets.traefik-redis-password.path;
    settings = {
      protected-mode = "no";
    };
  };

  # Redis can start before tailscale0 has its address; the firewall limits remote access to crisuflix.
  systemd.services.redis-traefik = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.traefik = {
    after = ["redis-traefik.service"];
    wants = ["redis-traefik.service"];
    serviceConfig.Environment = [
      "LEGO_DISABLE_CNAME_SUPPORT=true"
    ];
  };

  # Traefik reverse proxy
  services.traefik = {
    enable = true;

    # Inject DNS provider API tokens for ACME DNS-01 challenges
    # Also disable lego CNAME following to prevent zone-detection errors with apex domains
    environmentFiles = [
      config.age.secrets.desec-dns-token.path
      config.age.secrets.hetzner-dns-token-env-variable.path
      config.age.secrets.traefik-redis-env-vps.path
    ];

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
            certResolver = "hetzner";
            domains = [
              {
                main = "cri.su";
                sans = ["*.cri.su"];
              }
              {
                main = "vpn.cri.su";
                sans = ["*.vpn.cri.su"];
              }
              {
                main = "christiansandberg.fi";
                sans = ["*.christiansandberg.fi"];
              }
              {
                main = "sandbergs.fi";
                sans = ["*.sandbergs.fi"];
              }
              {
                main = "crisusandberg.fi";
                sans = ["*.crisusandberg.fi"];
              }
              {
                main = "csandberg.fi";
                sans = ["*.csandberg.fi"];
              }
            ];
          };
        };
      };

      certificatesResolvers = {
        # DNS-01 via Hetzner Cloud API — covers all Hetzner-hosted zones
        # Also aliased as "myresolver" for traefik-kop redis routers from crisuflix
        hetzner.acme = {
          email = "hetzner.traefikadmin@cri.su";
          storage = "/var/lib/traefik/acme.json";
          dnsChallenge = {
            provider = "hetzner";
            delayBeforeCheck = 10;
          };
        };
        myresolver.acme = {
          email = "hetzner.traefikadmin@cri.su";
          storage = "/var/lib/traefik/acme.json";
          dnsChallenge = {
            provider = "hetzner";
            delayBeforeCheck = 10;
          };
        };
        # DNS-01 via deSEC — covers csandberg.consulting (on deSEC nameservers)
        desec.acme = {
          email = "hetzner.traefikadmin@cri.su";
          storage = "/var/lib/traefik/acme.json";
          dnsChallenge = {
            provider = "desec";
            delayBeforeCheck = 10;
          };
        };
      };

      providers = {
        redis = {
          endpoints = ["${net.hosts.loopback}:${toString net.vps.redis.port}"];
          password = "$TRAEFIK_REDIS_PASSWORD";
          rootKey = "traefik";
        };
      };

      serversTransport.insecureSkipVerify = true;
    };

    # Dynamic configuration for the VPS edge and services hosted on crisuflix.
    # VPS-local service routes live beside their service definitions.
    dynamicConfigOptions = {
      http = {
        routers = {
          homeassistant = {
            rule = "Host(`ha.cri.su`)";
            entryPoints = ["websecure"];
            service = "homeassistant";
            tls.certResolver = "hetzner";
          };
          musicassistant = {
            rule = "Host(`ma.cri.su`)";
            entryPoints = ["websecure"];
            service = "musicassistant";
            tls.certResolver = "hetzner";
          };
          esphome = {
            rule = "Host(`esphome.vpn.cri.su`)";
            entryPoints = ["websecure"];
            service = "esphome";
            tls.certResolver = "hetzner";
            middlewares = ["tailnet-only"];
          };
          glances = {
            rule = "Host(`glances.vpn.cri.su`)";
            entryPoints = ["websecure"];
            service = "glances";
            tls.certResolver = "hetzner";
            middlewares = ["tailnet-only"];
          };
          homepage = {
            rule = "Host(`cri.su`)";
            entryPoints = ["websecure"];
            service = "homepage";
            tls.certResolver = "hetzner";
            middlewares = ["authelia-cri-su"];
          };
          opencloud = {
            rule = "Host(`cloud.cri.su`)";
            entryPoints = ["websecure"];
            service = "opencloud";
            tls.certResolver = "hetzner";
            # No Authelia — OpenCloud has its own authentication
          };
          collabora = {
            rule = "Host(`office.cri.su`)";
            entryPoints = ["websecure"];
            service = "collabora";
            tls.certResolver = "hetzner";
            # No Authelia — WOPI requests from OpenCloud must pass through unauthenticated
          };
          traefik-dashboard = {
            rule = "Host(`traefik.vpn.cri.su`)";
            entryPoints = ["websecure"];
            service = "traefik-api";
            tls.certResolver = "hetzner";
            middlewares = ["tailnet-only"];
          };
        };

        services = {
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
          musicassistant.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.musicAssistant.uiPort}";
            }
          ];
          esphome.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.esphome.uiPort}";
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
          traefik-api.loadBalancer.servers = [
            {
              url = "http://${net.hosts.loopback}:${toString net.vps.traefik.port}";
            }
          ];
        };

        middlewares = {
          tailnet-only.ipAllowList.sourceRange = ["100.64.0.0/10"];
        };
      };
    };
  };
}
