# Traefik VPS configuration module
# Provides reverse proxy with Redis for traefik-kop integration

{ config, ... }:

let
  net = config.christiansandbergNetwork;
in

{
  # Redis for traefik-kop (crisuflix publishes container routes here)
  services.redis.servers.traefik = {
    enable = true;
    bind = net.tailscaleIP;
    port = net.redisPort;
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
            domains = [{ main = net.domain; }];
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
          endpoints = ["${net.tailscaleIP}:${toString net.redisPort}"];
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
            rule = "Host(`auth.${net.domain}`)";
            entryPoints = [ "websecure" ];
            service = "authelia";
            tls.certResolver = "myresolver";
          };
          gotify = {
            rule = "Host(`gotify.${net.domain}`)";
            entryPoints = [ "websecure" ];
            service = "gotify";
            tls.certResolver = "myresolver";
          };
          uptime-kuma = {
            rule = "Host(`uptime.${net.domain}`)";
            entryPoints = [ "websecure" ];
            service = "uptime-kuma";
            tls.certResolver = "myresolver";
            middlewares = [ "authelia" ];
          };
          website = {
            rule = "Host(`${net.domain}`) || Host(`www.${net.domain}`)";
            entryPoints = [ "websecure" ];
            service = "website";
            tls.certResolver = "myresolver";
          };
        };

        services = {
          authelia.loadBalancer.servers = [{ 
            url = "http://${net.loopbackIP}:${toString net.autheliaPort}"; 
          }];
          gotify.loadBalancer.servers = [{ 
            url = "http://${net.loopbackIP}:${toString net.gotifyPort}"; 
          }];
          uptime-kuma.loadBalancer.servers = [{ 
            url = "http://${net.loopbackIP}:${toString net.uptimeKumaPort}"; 
          }];
          website.loadBalancer.servers = [{ 
            url = "http://${net.loopbackIP}:${toString net.websitePort}"; 
          }];
        };

        middlewares = {
          authelia.forwardAuth = {
            address = "http://${net.loopbackIP}:${toString net.autheliaPort}/api/authz/forward-auth?authelia_url=https%3A%2F%2Fauth.${net.domain}%2F";
            authResponseHeaders = [ "Remote-User" "Remote-Groups" "Remote-Email" "Remote-Name" ];
            trustForwardHeader = true;
          };
        };
      };
    };
  };
}
