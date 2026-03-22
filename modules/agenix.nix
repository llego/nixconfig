{inputs, config, hostname, lib, ...}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Define secrets based on hostname
  age.secrets = {
    # Initial user password - used by all hosts
    initial-password = {
      file = ./../secrets/initial-password.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };
  } // (
    # laptop + crisuflix secrets
    if builtins.elem hostname [ "laptop" "crisuflix" ] then {
      ha-mcp-token = {
        file = ./../secrets/ha-mcp-token.age;
        mode = "0400";
        owner = "llego";
        group = "users";
      };
    } else {}
  ) // (
    # Host-specific secrets
    if hostname == "crisuflix" then {
      nut-password = {
        file = ./../secrets/nut-password.age;
        path = "/run/keys/nut-password";
        mode = "0400";
        owner = "root";
        group = "root";
      };
      beszel-env = {
        file = ./../secrets/beszel-env.age;
        path = "/var/lib/beszel-agent/env";
        mode = "0600";
        owner = "root";
        group = "root";
      };
      cloudflare-ddns-token = {
        file = ./../secrets/cloudflare-ddns-token.age;
        mode = "0400";
        owner = "cloudflare-ddns";
        group = "cloudflare-ddns";
      };
      esphome-dashboard-env = {
        file = ./../secrets/esphome-dashboard-env.age;
        mode = "0400";
        owner = "root";
        group = "root";
      };
      mosquitto-mqtt-user-password = {
        file = ./../secrets/mosquitto-mqtt-user-password.age;
        mode = "0400";
        owner = "mosquitto";
        group = "mosquitto";
      };
    } else if hostname == "christiansandberg" then {
      cloudflare-ddns-token = {
        file = ./../secrets/cloudflare-ddns-token.age;
        mode = "0400";
        owner = "cloudflare-ddns";
        group = "cloudflare-ddns";
      };
      authelia-jwt = {
        file = ./../secrets/authelia-christiansandberg-jwt.age;
        mode = "0400";
        owner = "authelia-christiansandberg";
        group = "authelia-christiansandberg";
      };
      authelia-storage = {
        file = ./../secrets/authelia-christiansandberg-storage.age;
        mode = "0400";
        owner = "authelia-christiansandberg";
        group = "authelia-christiansandberg";
      };
      authelia-session = {
        file = ./../secrets/authelia-christiansandberg-session.age;
        mode = "0400";
        owner = "authelia-christiansandberg";
        group = "authelia-christiansandberg";
      };
      authelia-smtp = {
        file = ./../secrets/authelia-christiansandberg-smtp.age;
        mode = "0400";
        owner = "authelia-christiansandberg";
        group = "authelia-christiansandberg";
      };
    } else {}
  );

  # Expose HA MCP token as environment variable on laptop and crisuflix
  environment.extraInit = lib.mkIf (builtins.elem hostname [ "laptop" "crisuflix" ]) ''
    if [ -r /run/agenix/ha-mcp-token ]; then
      export HA_MCP_TOKEN=$(cat /run/agenix/ha-mcp-token)
    fi
  '';
}
