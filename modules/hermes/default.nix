{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.hermes-agent.nixosModules.default
    ./signal.nix
    ./oura.nix
  ];

  services.hermes-agent = {
    enable = true;
    configFile = ./config.yaml;
    environmentFiles = [config.age.secrets.hermes-env.path];
    addToSystemPackages = true;
    extraPackages = [pkgs.signal-cli];
    extraDependencyGroups = ["messaging" "mcp"];
  };

  # The upstream module sets MESSAGING_CWD to workspace/; override it to .hermes/ so
  # the daemon's read_file resolves paths the same way the CLI does.
  systemd.services.hermes-agent.environment.MESSAGING_CWD =
    lib.mkForce "/var/lib/hermes/.hermes";

  # The upstream module omits cache/ and doesn't fix files written by interactive
  # sessions (login user, not service user). Correct everything recursively on deploy.
  system.activationScripts."hermes-fix-permissions" = {
    deps = ["hermes-agent-setup"];
    text = ''
      HERMES_HOME=/var/lib/hermes/.hermes
      mkdir -p "$HERMES_HOME/cache/images"
      chown -R hermes:hermes "$HERMES_HOME"
      find "$HERMES_HOME" -type d -exec chmod 2770 {} +
      find "$HERMES_HOME" -type f -exec chmod 0640 {} +
    '';
  };
}
