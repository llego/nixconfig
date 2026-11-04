{config, ...}: let
  net = config.networkVars;
in {
  age.secrets."pocket-id-encryption-key" = {
    owner = config.services.pocket-id.user;
    group = config.services.pocket-id.group;
  };

  services.pocket-id = {
    enable = true;
    credentials = {
      ENCRYPTION_KEY = config.age.secrets."pocket-id-encryption-key".path;
    };
    settings = {
      # <https://pocket-id.org/docs/configuration/environment-variables>
      APP_URL = "https://id.cri.su";
      TRUST_PROXY = true;
      HOST = "127.0.0.1";
      PORT = net.vps.pocketId.port;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.pocket-id = {
      rule = "Host(`id.cri.su`)";
      entryPoints = ["websecure"];
      service = "pocket-id";
      tls.certResolver = "hetzner";
    };

    services.pocket-id.loadBalancer.servers = [
      {
        url = "http://127.0.0.1:${toString net.vps.pocketId.port}";
      }
    ];
  };
}
