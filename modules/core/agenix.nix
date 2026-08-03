{
  inputs,
  pkgs,
  hostname,
  lib,
  reporoot,
  ...
}: let
  registry = import (reporoot + "/secrets/_registry.nix");

  secretsForHost =
    lib.filterAttrs (
      _name: secret: builtins.elem hostname (secret.hosts or [])
    )
    registry.secrets;

  runtimeSecret = name: secret:
    {
      file = reporoot + "/secrets/${name}.age";
    }
    // builtins.removeAttrs secret ["publicKeys" "hosts"];
in {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  age.secrets = lib.mapAttrs runtimeSecret secretsForHost;

  # Expose secrets as environment variables on laptop and crisuflix
  environment.extraInit = lib.mkIf (builtins.elem hostname ["laptop" "crisuflix"]) ''
    if [ -r /run/agenix/ha-mcp-token ]; then
      export HA_MCP_TOKEN=$(cat /run/agenix/ha-mcp-token)
    fi
  '';
}
