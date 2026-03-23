# Traefik VPS configuration module
# Provides reverse proxy with Redis for traefik-kop integration

{ ... }:

{
  # Redis for traefik-kop (crisuflix publishes container routes here)
  services.redis.servers.traefik = {
    enable = true;
    bind = "100.78.37.16";
    port = 6379;
    settings = {
      protected-mode = "no";
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
            domains = [{ main = "christiansandberg.fi"; }];
          };
        };
      };

      certificatesResolvers.myresolver.acme = {
        email = "traefik.certs@cri.su";
        storage = "/var/lib/traefik/acme.json";
        httpChallenge.entryPoint = "web";
      };

      providers = {
        docker = {
          exposedByDefault = false;
          endpoint = "unix:///var/run/docker.sock";
        };
        redis = {
          endpoints = ["100.78.37.16:6379"];
          rootKey = "traefik";
        };
      };

      serversTransport.insecureSkipVerify = true;
    };

    # Dynamic configuration for native services (Authelia, Gotify, Uptime Kuma)
    dynamicConfigOptions = {
      http = {
        routers = {
          authelia = {
            rule = "Host(`auth.christiansandberg.fi`)";
            entryPoints = [ "websecure" ];
            service = "authelia";
            tls.certResolver = "myresolver";
          };
          gotify = {
            rule = "Host(`gotify.christiansandberg.fi`)";
            entryPoints = [ "websecure" ];
            service = "gotify";
            tls.certResolver = "myresolver";
          };
          uptime-kuma = {
            rule = "Host(`uptime.christiansandberg.fi`)";
            entryPoints = [ "websecure" ];
            service = "uptime-kuma";
            tls.certResolver = "myresolver";
            middlewares = [ "authelia" ];
          };
        };

        services = {
          authelia.loadBalancer.servers = [{ url = "http://172.21.0.1:9091"; }];
          gotify.loadBalancer.servers = [{ url = "http://172.21.0.1:8079"; }];
          uptime-kuma.loadBalancer.servers = [{ url = "http://172.21.0.1:3001"; }];
        };

        middlewares = {
          authelia.forwardAuth = {
            address = "http://172.21.0.1:9091/api/authz/forward-auth?authelia_url=https%3A%2F%2Fauth.christiansandberg.fi%2F";
            authResponseHeaders = [ "Remote-User" "Remote-Groups" "Remote-Email" "Remote-Name" ];
            trustForwardHeader = true;
          };
        };
      };
    };
  };

  # Allow Traefik to read Docker socket
  systemd.services.traefik.serviceConfig = {
    SupplementaryGroups = [ "docker" ];
  };
}
