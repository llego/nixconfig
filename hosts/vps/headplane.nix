{config, ...}: let
  net = config.networkVars;
in {
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
      };
      integration.agent = {
        enabled = false;
      };
    };
  };
}
