# Traefik VPS configuration module
# Provides reverse proxy with Redis for traefik-kop integration
{
  config,
  inputs,
  ...
}: let
  net = config.networkVars;
in {
  imports = ["${inputs.hetzner_ddns}/release/NixOS/nixos_module.nix"];

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

  services.hetzner_ddns = {
    enable = true;
    zones = [
      {
        domain = "cri.su";
        records = [{name = "@";}];
      }
      {
        domain = "christiansandberg.fi";
        records = [{name = "@";}];
      }
      {
        domain = "sandbergs.fi";
        records = [{name = "@";}];
      }
      {
        domain = "crisusandberg.fi";
        records = [{name = "@";}];
      }
      {
        domain = "csandberg.fi";
        records = [{name = "@";}];
      }
    ];
    protections = true; # enables protection settings in the systemd service. might cause permission problems with reading the api_key_file
    api_key_file = "/run/credentials/hetzner_ddns.service/hetzner-dns-token";
  };

  systemd.services.hetzner_ddns.serviceConfig.LoadCredential = "hetzner-dns-token:${config.age.secrets.hetzner-dns-token.path}";

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

  systemd.services.traefik.serviceConfig.Environment = [
    "LEGO_DISABLE_CNAME_SUPPORT=true"
  ];

  # Traefik reverse proxy
  services.traefik = {
    enable = true;

    # Inject DNS provider API tokens for ACME DNS-01 challenges
    # Also disable lego CNAME following to prevent zone-detection errors with apex domains
    environmentFiles = [
      config.age.secrets.desec-dns-token.path
      config.age.secrets.hetzner-dns-token.path
      config.age.secrets.hetzner-dns-token.path
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
            rule = "Host(`christiansandberg.fi`) || Host(`sandbergs.fi`) || Host(`crisusandberg.fi`) || Host(`csandberg.fi`)";
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
              domains = [
                {
                  main = "csandberg.consulting";
                  sans = ["*.csandberg.consulting"];
                }
              ];
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
          headscale = {
            rule = "Host(`headscale.cri.su`)";
            entryPoints = ["websecure"];
            service = "headscale";
            tls.certResolver = "hetzner";
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
          headscale.loadBalancer = {
            servers = [
              {
                url = "http://${net.hosts.loopback}:${toString net.vps.headscale.port}";
              }
            ];
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

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = net.vps.headscale.port;

    settings = {
      server_url = "https://headscale.cri.su";

      # dns_config = {
      #   override_local_dns = true;
      #   base_domain = "${net.domain}";
      #   magic_dns = true;
      #   domains = ["tailscale.${net.domain}"];
      #   nameservers = [
      #     "9.9.9.9" # no cloudflare, nice
      #   ];
      # };

      dns = {
        magic_dns = true;
        base_domain = "tailnet.cri.su";
        nameservers.global = ["9.9.9.9"];
      };
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };
    };
  };
}
