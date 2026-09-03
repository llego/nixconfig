{
  config,
  pkgs,
  ...
}: let
  net = config.networkVars;
in {
  environment.systemPackages = [pkgs.signal-cli];

  # signal-cli HTTP daemon — required by the hermes Signal adapter.
  # Reads SIGNAL_ACCOUNT from the hermes env secret at runtime.
  #
  # One-time setup (before this service is useful):
  #   1. Run: signal-cli link -n "HermesAgent"
  #      Scan the QR code from your phone → Settings → Linked Devices.
  #   2. Add to secrets/hermes-env.age:
  #        SIGNAL_HTTP_URL=http://127.0.0.1:8089
  #        SIGNAL_ACCOUNT=+358407435858
  #        SIGNAL_ALLOWED_USERS=+358407435858
  #        SIGNAL_HOME_CHANNEL=+358407435858
  #   3. Re-encrypt, deploy, then: systemctl start signal-cli
  #
  # No firewall rule needed — daemon binds to loopback only (127.0.0.1).
  systemd.services.signal-cli = {
    description = "signal-cli HTTP daemon for hermes-agent Signal adapter";
    after = ["network-online.target"];
    requires = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    unitConfig.ConditionPathExists = config.age.secrets.hermes-env.path;

    serviceConfig = {
      Type = "simple";
      User = "hermes";
      Group = "hermes";
      EnvironmentFile = config.age.secrets.hermes-env.path;
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec ${pkgs.signal-cli}/bin/signal-cli --config /var/lib/hermes/signal-cli --account \"$SIGNAL_ACCOUNT\" daemon --http 127.0.0.1:${toString net.crisuflix.signalCli.port}'";
      Restart = "always";
      RestartSec = 10;
      StateDirectory = "hermes/signal-cli";
      WorkingDirectory = "/var/lib/hermes/signal-cli";
    };
  };
}
