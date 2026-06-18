{config, ...}: let
  net = config.networkVars;
in {
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = net.vps.headscale.port;

    settings = {
      server_url = "https://headscale.cri.su";

      dns = {
        magic_dns = true;
        base_domain = "tailnet.cri.su";
        nameservers = {
          global = ["9.9.9.9"];
          split = {
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
