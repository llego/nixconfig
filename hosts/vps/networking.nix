# Traefik VPS configuration module
# Provides reverse proxy with Redis for traefik-kop integration
{
  config,
  pkgs,
  ...
}: let
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

  # Hetzner DDNS for all VPS domains — updates A records via Hetzner Cloud API
  # Covers: cri.su, christiansandberg.fi, sandbergs.fi, crisusandberg.fi, csandberg.fi
  systemd.services.hetzner-ddns = {
    description = "Hetzner DDNS update for all VPS A records";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "hetzner-ddns";
      ExecStart = pkgs.writeShellScript "hetzner-ddns" ''
        TOKEN=$(grep '^HETZNER_API_TOKEN=' ${config.age.secrets.hetzner-dns-token.path} | cut -d= -f2)
        IP=$(${pkgs.curl}/bin/curl -sf https://api.ipify.org)
        if [ -z "$IP" ]; then
          echo "Failed to get public IP" >&2
          exit 1
        fi
        for ZONE in cri.su christiansandberg.fi sandbergs.fi crisusandberg.fi csandberg.fi; do
          CACHE=/var/lib/hetzner-ddns/$ZONE.ip
          if [ -f "$CACHE" ] && [ "$(cat "$CACHE")" = "$IP" ]; then
            echo "$ZONE: IP unchanged ($IP), skipping"
            continue
          fi
          echo "$ZONE: updating A record to $IP"
          ${pkgs.curl}/bin/curl -sf -X DELETE \
            -H "Authorization: Bearer $TOKEN" \
            "https://api.hetzner.cloud/v1/zones/$ZONE/rrsets/@/A" || true
          ${pkgs.curl}/bin/curl -sf -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"@\",\"type\":\"A\",\"ttl\":300,\"records\":[{\"value\":\"$IP\",\"comment\":\"\"}],\"labels\":{}}" \
            "https://api.hetzner.cloud/v1/zones/$ZONE/rrsets"
          echo "$IP" > "$CACHE"
          echo "$ZONE: done"
        done
      '';
    };
  };

  systemd.timers.hetzner-ddns = {
    wantedBy = ["timers.target"];
    description = "Hetzner DDNS timer for all VPS domains";
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Unit = "hetzner-ddns.service";
    };
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

    # Inject DNS provider API tokens for ACME DNS-01 challenges
    # Also disable lego CNAME following to prevent zone-detection errors with apex domains
    environmentFiles = [
      config.age.secrets.hetzner-dns-token.path
      config.age.secrets.desec-dns-token.path
      (pkgs.writeText "traefik-lego-env" ''
        LEGO_DISABLE_CNAME_SUPPORT=true
      '')
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
              {main = "cri.su";               sans = ["*.cri.su"];}
              {main = "christiansandberg.fi";  sans = ["*.christiansandberg.fi"];}
              {main = "sandbergs.fi";          sans = ["*.sandbergs.fi"];}
              {main = "crisusandberg.fi";      sans = ["*.crisusandberg.fi"];}
              {main = "csandberg.fi";          sans = ["*.csandberg.fi"];}
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
            tls.certResolver = "hetzner";
          };
          gotify = {
            rule = "Host(`gotify.cri.su`)";
            entryPoints = ["websecure"];
            service = "gotify";
            tls.certResolver = "hetzner";
          };
          uptime-kuma = {
            rule = "Host(`uptime.cri.su`)";
            entryPoints = ["websecure"];
            service = "uptime-kuma";
            tls.certResolver = "hetzner";
            middlewares = ["authelia-cri-su"];
          };
          # Hetzner-hosted domains
          website = {
            rule = "Host(`christiansandberg.fi`) || Host(`www.christiansandberg.fi`) || Host(`sandbergs.fi`) || Host(`www.sandbergs.fi`) || Host(`crisusandberg.fi`) || Host(`csandberg.fi`)";
            entryPoints = ["websecure"];
            service = "website";
            tls.certResolver = "hetzner";
          };
          # csandberg.consulting is on deSEC — needs its own resolver and wildcard cert
          website-consulting = {
            rule = "Host(`csandberg.consulting`)";
            entryPoints = ["websecure"];
            service = "website";
            tls = {
              certResolver = "desec";
              domains = [{main = "csandberg.consulting"; sans = ["*.csandberg.consulting"];}];
            };
          };
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
          glances = {
            rule = "Host(`glances.cri.su`)";
            entryPoints = ["websecure"];
            service = "glances";
            tls.certResolver = "hetzner";
            middlewares = ["authelia-cri-su"];
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
          musicassistant.loadBalancer.servers = [
            {
              url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.musicAssistant.uiPort}";
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
