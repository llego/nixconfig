{
  config,
  inputs,
  pkgs,
  ...
}: let
  net = config.networkVars;
in {
  disabledModules = ["services/networking/headplane.nix"];

  imports = [inputs.headplane.nixosModules.headplane];

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = net.vps.headscale.port;

    settings = {
      server_url = "https://headscale.cri.su";
      listen_addr = "127.0.0.1:${toString net.vps.headscale.port}";
      trusted_proxies = ["127.0.0.1/32" "::1/128"];
      tls_cert_path = null;
      tls_key_path = null;

      dns = {
        magic_dns = true;
        base_domain = "tailnet.cri.su";
        search_domains = ["tailnet.cri.su"];
        nameservers = {
          global = [
            "https://dns.controld.com/wrpogws0c1"
            "76.76.2.22"
            # "9.9.9.9"
          ];
          split = {
            # Headscale extra_records do not wildcard-match. Route the private
            # service namespace to dnsmasq, which answers *.vpn.cri.su with the
            # VPS tailnet IP while keeping the public cri.su zone untouched.
            "vpn.cri.su." = [net.hosts.vps];
            "home." = ["192.168.1.1"];
            "iot." = ["192.168.3.1"];
          };
        };
      };
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };
      policy = {
        mode = "file";
        path = pkgs.writeText "headscale-policy.hujson" ''
          {
            // Keep the existing tailnet behavior: all nodes may talk to all other
            // nodes. Adding any policy file replaces Headscale's implicit defaults.
            "acls": [
              {
                "action": "accept",
                "src": ["*"],
                "dst": ["*:*"]
              }
            ],

            // Browser SSH/Tailscale SSH requires an explicit SSH rule. Limit it to
            // same-owner devices and the local non-root account used on NixOS hosts.
            "ssh": [
              {
                "action": "accept",
                "src": ["autogroup:member"],
                "dst": ["autogroup:self"],
                "users": ["llego"]
              }
            ]
          }
        '';
      };
      oidc = {
        issuer = "https://auth.cri.su";
        client_id = "headscale";
        client_secret_path = config.age.secrets.headscale-oidc-client-secret.path;
        scope = ["openid" "profile" "email" "groups"];
        pkce = {
          enabled = true;
          method = "S256";
        };
      };
    };
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      # Serve split DNS only on the tailnet; public DNS for cri.su remains with
      # Hetzner. This lets Docker services use *.vpn.cri.su labels without
      # adding one Headscale DNS record per service.
      interface = "tailscale0";
      bind-interfaces = true;
      listen-address = net.hosts.vps;
      address = ["/vpn.cri.su/${net.hosts.vps}"];

      # Forward anything outside the split zone if a client queries this
      # resolver directly.
      server = ["76.76.2.22"];
    };
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  systemd.services.dnsmasq = {
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    preStart = ''
      for _ in $(seq 1 60); do
        if ${pkgs.iproute2}/bin/ip addr show tailscale0 | ${pkgs.gnugrep}/bin/grep -q ${net.hosts.vps}; then
          exit 0
        fi
        sleep 1
      done
      echo "Timed out waiting for ${net.hosts.vps} on tailscale0" >&2
      exit 1
    '';
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  nixpkgs.overlays = [inputs.headplane.overlays.default];

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = net.vps.headplane.port;
        base_url = "https://headplane.vpn.cri.su";
        cookie_secure = true;
        cookie_secret_path = config.age.secrets.headplane-cookie-secret.path;
      };
      headscale = {
        url = "https://headscale.cri.su";
        public_url = "https://headscale.cri.su";
        config_path = config.services.headscale.configFile;
        api_key_path = config.age.secrets.headscale-api-key.path;
      };
      oidc = {
        issuer = "https://auth.cri.su";
        client_id = "headscale";
        client_secret_path = config.age.secrets.headscale-oidc-client-secret.path;
        use_pkce = true;
        token_endpoint_auth_method = "client_secret_basic";
      };
      integration.agent = {
        enabled = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/headplane/agent 0700 headscale headscale - -"
  ];

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      headscale = {
        rule = "Host(`headscale.cri.su`)";
        entryPoints = ["websecure"];
        service = "headscale";
        tls.certResolver = "hetzner";
        # Browser SSH runs from headplane.vpn.cri.su but needs direct browser
        # access to Headscale's DERP/WebSocket endpoints on headscale.cri.su.
        middlewares = ["headscale-cors"];
      };
      headplane = {
        rule = "Host(`headplane.vpn.cri.su`)";
        entryPoints = ["websecure"];
        service = "headplane";
        tls.certResolver = "hetzner";
        middlewares = ["tailnet-only"];
      };
    };

    services = {
      headscale.loadBalancer = {
        servers = [
          {
            url = "http://${net.hosts.loopback}:${toString net.vps.headscale.port}";
          }
        ];
        passHostHeader = true;
      };
      headplane.loadBalancer.servers = [
        {
          url = "http://${net.hosts.loopback}:${toString net.vps.headplane.port}";
        }
      ];
    };

    middlewares.headscale-cors.headers = {
      accessControlAllowOriginList = ["https://headplane.vpn.cri.su"];
      accessControlAllowMethods = ["GET" "POST" "OPTIONS"];
      accessControlAllowHeaders = [
        "Content-Type"
        "Upgrade"
        "Sec-WebSocket-Protocol"
      ];
      addVaryHeader = true;
    };
  };
}
