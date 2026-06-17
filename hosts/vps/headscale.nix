{config, ...}: let
  net = config.networkVars;
in {
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
        extra_records = [
          {
            name = "laptop.tailnet.cri.su";
            type = "A";
            value = "100.64.0.1";
          }
          {
            name = "vps.tailnet.cri.su";
            type = "A";
            value = "100.64.0.2";
          }
          {
            name = "crisuflix.tailnet.cri.su";
            type = "A";
            value = "100.64.0.3";
          }
          {
            name = "rpi5.tailnet.cri.su";
            type = "A";
            value = "100.64.0.4";
          }
        ];
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
}
