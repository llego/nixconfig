{
  config,
  pkgs,
  username,
  ...
}: let
  net = config.networkVars;
in {
  # Share the user's normal config, provider credentials, sessions, and projects.
  # --service also registers this foreground process for local CLI discovery/pairing.
  systemd.services.opencode = {
    description = "OpenCode V2 API and web server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "tailscaled.service" "tailscaled-set.service"];
    wants = ["network-online.target" "tailscaled.service" "tailscaled-set.service"];
    path = [config.system.path];
    environment.HOME = "/home/${username}";

    preStart = ''
      for _ in $(seq 1 120); do
        if [ "$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null)" = "${net.tailnetIPs.crisuflix}" ]; then
          exit 0
        fi
        sleep 1
      done
      echo "Timed out waiting for Tailscale IPv4 ${net.tailnetIPs.crisuflix}"
      exit 1
    '';

    script = ''
      # Shared-service mode reads its saved password, not OPENCODE_PASSWORD.
      # Use the supported CLI rather than editing its private service files.
      # These setters stop an incumbent daemon when a setting changes, allowing
      # systemd to take ownership on the first deployment.
      if [ "$(${pkgs.opencode}/bin/opencode service get hostname)" != "${net.tailnetIPs.crisuflix}" ]; then
        ${pkgs.opencode}/bin/opencode service set hostname ${net.tailnetIPs.crisuflix}
      fi
      if [ "$(${pkgs.opencode}/bin/opencode service get port)" != "${toString net.crisuflix.opencode.port}" ]; then
        ${pkgs.opencode}/bin/opencode service set port ${toString net.crisuflix.opencode.port}
      fi
      if [ "$(${pkgs.opencode}/bin/opencode service get password)" != "$OPENCODE_PASSWORD" ]; then
        ${pkgs.opencode}/bin/opencode service set password "$OPENCODE_PASSWORD"
      fi
      if [ "$(${pkgs.opencode}/bin/opencode service get remote)" = true ]; then
        ${pkgs.opencode}/bin/opencode service set remote false
      fi
      # Do not pass the server password to agent tool processes.
      unset OPENCODE_PASSWORD

      # System services do not inherit the interactive shell's MCP credentials.
      export HA_MCP_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/ha-mcp-token")"
      export HOMELABLE_MCP_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/homelable-mcp-api-key")"
      exec ${pkgs.opencode}/bin/opencode serve --service \
        --hostname ${net.tailnetIPs.crisuflix} \
        --port ${toString net.crisuflix.opencode.port}
    '';

    serviceConfig = {
      User = username;
      Group = "users";
      WorkingDirectory = "/home/${username}/nixconfig";
      EnvironmentFile = config.age.secrets.opencode-server-env.path;
      LoadCredential = [
        "ha-mcp-token:${config.age.secrets.ha-mcp-token.path}"
        "homelable-mcp-api-key:${config.age.secrets.homelable-mcp-api-key.path}"
      ];
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "150s";
      UMask = "0077";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [net.crisuflix.opencode.port];
}
