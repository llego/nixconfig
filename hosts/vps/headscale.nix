{config, ...}: let
  net = config.networkVars;
in {
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
            # Tailscale/Headscale extra_records do not wildcard-match; they only
            # answer the literal "*.llego.me" name. Send the whole zone to a
            # tailnet-only dnsmasq responder instead.
            "llego.me." = ["100.64.0.4"];
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
      # Only listen on the VPS tailnet interface; this DNS responder exists
      # solely for Headscale split DNS clients.
      interface = "tailscale0";
      "bind-interfaces" = true;
      "no-resolv" = true;

      # Wildcard the entire llego.me zone to crisuflix's tailnet IP so internal
      # Traefik receives *.llego.me requests over Headscale instead of public DNS.
      address = ["/llego.me/100.64.0.1"];
    };
  };

  systemd.services.dnsmasq = {
    # tailscale0 must exist before dnsmasq binds to it; if tailscaled restarts
    # and recreates the interface, restart dnsmasq so it re-binds cleanly.
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    partOf = ["tailscaled.service"];
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = net.vps.headplane.port;
        base_url = "https://headplane.cri.su";
        cookie_secure = true;
        cookie_secret_path = config.age.secrets.headplane-cookie-secret.path;
      };
      headscale = {
        url = "https://headscale.cri.su";
      };
      oidc = {
        issuer = "https://auth.cri.su";
        client_id = "headscale";
        client_secret_path = config.age.secrets.headscale-oidc-client-secret.path;
        headscale_api_key_path = config.age.secrets.headscale-api-key.path;
        use_pkce = true;
        token_endpoint_auth_method = "client_secret_basic";
      };
      integration.agent = {
        enabled = false;
      };
    };
  };
}
