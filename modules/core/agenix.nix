{
  inputs,
  pkgs,
  hostname,
  lib,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];
  
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Define secrets based on hostname
  age.secrets =
    {
      # Initial user password - used by all hosts
      initial-password = {
        file = ./../../secrets/initial-password.age;
        mode = "0400";
        owner = "root";
        group = "root";
      };
      beszel-env = {
        file = ./../../secrets/beszel-env.age;
        path = "/var/lib/beszel-agent/env";
        mode = "0640";
        owner = "root";
        group = "beszel-agent";
      };
      # Bandcamp cookie for album-downloader - available on all hosts
      bandcamp-cookie = {
        file = ./../../secrets/bandcamp-cookie.age;
        mode = "0400";
        owner = "llego";
        group = "users";
      };
    }
    // (
      # laptop + crisuflix secrets
      if builtins.elem hostname ["laptop" "crisuflix"]
      then {
        ha-mcp-token = {
          file = ./../../secrets/ha-mcp-token.age;
          mode = "0400";
          owner = "llego";
          group = "users";
        };
        supermemory-api-key = {
          file = ./../../secrets/supermemory-api-key.age;
          mode = "0400";
          owner = "llego";
          group = "users";
        };
      }
      else {}
    )
    // (
      # Host-specific secrets
      if hostname == "crisuflix"
      then {
        nut-password = {
          file = ./../../secrets/nut-password.age;
          path = "/run/keys/nut-password";
          mode = "0400";
          owner = "root";
          group = "root";
        };
        esphome-dashboard-env = {
          file = ./../../secrets/esphome-dashboard-env.age;
          mode = "0400";
          owner = "root";
          group = "root";
        };
        mosquitto-mqtt-user-password = {
          file = ./../../secrets/mosquitto-mqtt-user-password.age;
          mode = "0400";
          owner = "mosquitto";
          group = "mosquitto";
        };
        restic-storj-password = {
          file = ./../../secrets/restic-storj-password.age;
          mode = "0400";
          owner = "root";
          group = "root";
        };
        storj-s3-credentials = {
          file = ./../../secrets/storj-s3-credentials.age;
          path = "/var/lib/restic/storj-s3-credentials";
          mode = "0400";
          owner = "root";
          group = "root";
        };
      }
      else if hostname == "vps"
      then {
        cloudflare-ddns-token = {
          file = ./../../secrets/cloudflare-ddns-token.age;
          mode = "0400";
          owner = "cloudflare-ddns";
          group = "cloudflare-ddns";
        };
        # cri.su authelia secrets
        "authelia-cri.su-jwt" = {
          file = ./../../secrets/authelia-cri.su-jwt.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        "authelia-cri.su-storage" = {
          file = ./../../secrets/authelia-cri.su-storage.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        "authelia-cri.su-session" = {
          file = ./../../secrets/authelia-cri.su-session.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        "authelia-cri.su-oidc-hmac" = {
          file = ./../../secrets/authelia-cri.su-oidc-hmac.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        "authelia-cri.su-oidc-private-key" = {
          file = ./../../secrets/authelia-cri.su-oidc-private-key.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        "authelia-cri.su-openwebui-secret" = {
          file = ./../../secrets/authelia-cri.su-openwebui-secret.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        "authelia-cri.su-smtp" = {
          file = ./../../secrets/authelia-cri.su-smtp.age;
          mode = "0400";
          owner = "authelia-cri.su";
          group = "authelia-cri.su";
        };
        gotify-admin-password = {
          file = ./../../secrets/gotify-admin-password.age;
          mode = "0400";
          owner = "root";
          group = "root";
        };
      }
      else {}
    );

  # Expose secrets as environment variables on laptop and crisuflix
  environment.extraInit = lib.mkIf (builtins.elem hostname ["laptop" "crisuflix"]) ''
    if [ -r /run/agenix/ha-mcp-token ]; then
      export HA_MCP_TOKEN=$(cat /run/agenix/ha-mcp-token)
    fi
    if [ -r /run/agenix/supermemory-api-key ]; then
      export SUPERMEMORY_API_KEY=$(cat /run/agenix/supermemory-api-key)
    fi
  '';
}
