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
    } else {}
  );

  # Expose HA MCP token as environment variable on laptop and crisuflix
  environment.extraInit = lib.mkIf (builtins.elem hostname [ "laptop" "crisuflix" ]) ''
    if [ -r /run/agenix/ha-mcp-token ]; then
      export HA_MCP_TOKEN=$(cat /run/agenix/ha-mcp-token)
    fi
  '';
}
