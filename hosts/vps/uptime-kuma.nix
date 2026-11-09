{config, ...}: let
  net = config.networkVars;
in {
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString net.vps.uptimeKuma.port;
      HOST = "127.0.0.1";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.uptime-kuma = {
      rule = "Host(`uptime.vpn.cri.su`)";
      entryPoints = ["websecure"];
      service = "uptime-kuma";
      tls.certResolver = "hetzner";
      middlewares = ["tailnet-only"];
    };

    services.uptime-kuma.loadBalancer.servers = [
      {
        url = "http://127.0.0.1:${toString net.vps.uptimeKuma.port}";
      }
    ];
  };
}
