{
  config,
  inputs,
  pkgs,
  ...
}: let
  net = config.networkVars;
  website = pkgs.runCommand "christiansandberg-website" {} ''
    mkdir -p $out
    cp -r ${inputs.christiansandberg-website}/* $out/
  '';
in {
  services.static-web-server = {
    enable = true;
    listen = "127.0.0.1:${toString net.vps.website.port}";
    root = "${website}";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      # Hetzner-hosted domains
      website = {
        rule = "Host(`christiansandberg.fi`) || Host(`sandbergs.fi`) || Host(`crisusandberg.fi`) || Host(`csandberg.fi`)";
        entryPoints = ["websecure"];
        service = "website";
        tls.certResolver = "hetzner";
      };
      # csandberg.consulting is on deSEC -- needs its own resolver and wildcard cert
      website-consulting = {
        rule = "Host(`csandberg.consulting`)";
        entryPoints = ["websecure"];
        service = "website";
        tls = {
          certResolver = "desec";
          domains = [
            {
              main = "csandberg.consulting";
              sans = ["*.csandberg.consulting"];
            }
          ];
        };
      };
    };

    services.website.loadBalancer.servers = [
      {
        url = "http://127.0.0.1:${toString net.vps.website.port}";
      }
    ];
  };
}
