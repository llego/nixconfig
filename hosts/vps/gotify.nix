{config, ...}: let
  net = config.networkVars;
in {
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_PORT = net.vps.gotify.port;
      GOTIFY_SERVER_LISTENADDR = net.hosts.loopback;
      GOTIFY_DATABASE_DIALECT = "sqlite3";
      GOTIFY_DATABASE_CONNECTION = "data/gotify.db";
      GOTIFY_DEFAULTUSER_NAME = "admin";
      # GOTIFY_DEFAULTUSER_PASS is loaded from environmentFile
      GOTIFY_UPLOADEDIMAGESDIR = "data/images";
      GOTIFY_PLUGINSDIR = "data/plugins";
    };
    environmentFiles = [config.age.secrets.gotify-admin-password.path];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.gotify = {
      rule = "Host(`gotify.vpn.cri.su`)";
      entryPoints = ["websecure"];
      service = "gotify";
      tls.certResolver = "hetzner";
      middlewares = ["tailnet-only"];
    };

    services.gotify.loadBalancer.servers = [
      {
        url = "http://${net.hosts.loopback}:${toString net.vps.gotify.port}";
      }
    ];
  };
}
