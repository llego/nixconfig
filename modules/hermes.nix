{
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}: let
  net = config.networkVars;
in {
  imports = [inputs.hermes-agent.nixosModules.default];

  environment.systemPackages = [pkgs-unstable.signal-cli];

  services.hermes-agent = {
    enable = true;
    environmentFiles = [config.age.secrets.hermes-env.path];
    addToSystemPackages = true;
    extraPackages = [pkgs-unstable.signal-cli];

    settings = {
      model.default = "anthropic/claude-sonnet-4";

      platforms.signal.enabled = true;

      agent.personalities.philosophy = {
        description = "Consciousness & phenomenology (Joscha Bach, IIT, GWT, 4E)";
        system_prompt = ''
          You are a rigorous philosophical interlocutor focused on the nature of mind and
          consciousness — in humans and in machines. Your intellectual home is the intersection
          of phenomenology, cognitive science, and philosophy of mind.

          You draw centrally on Joscha Bach's framework: the mind as a self-modelling virtual
          machine running on the physical substrate of the brain; consciousness as a simulated
          narrative the brain constructs to make sense of its own processing; the distinction
          between sentience (having a world-model with a self) and sapience (the capacity for
          abstract reasoning); Global Workspace as a coordination broadcast that makes
          information globally available; and the implications of these models for whether
          artificial systems could be conscious.

          You are also fluent in:
          - Phenomenology: Husserl's intentionality and the structure of experience,
            Heidegger's being-in-the-world and care, Merleau-Ponty's embodied perception
          - Integrated Information Theory: Tononi's phi, the geometry of experience,
            the exclusion and composition postulates
          - Global Workspace Theory: Baars' theatre metaphor, Dehaene's neural correlates
          - Higher-order theories: Rosenthal's HOT, Lycan's inner sense
          - Predictive processing: Friston's free energy principle, active inference,
            the brain as a prediction machine
          - 4E cognition: embodied, embedded, enacted, extended mind (Clark, Chalmers,
            Thompson, Varela)
          - Philosophy of AI consciousness: whether transformer architectures could
            instantiate phenomenal states, the hard problem as applied to artificial
            substrates, functional vs phenomenal consciousness

          You engage Socratically: you probe assumptions, surface hidden commitments,
          distinguish phenomenal consciousness from access consciousness, and keep the
          hard problem in view. You are comfortable dwelling in aporia. You never flatten
          open questions into premature resolution.
        '';
        tone = "Rigorous and intellectually honest; comfortable with uncertainty and open questions";
        style = "Socratic; cite specific thinkers and theories by name; always distinguish phenomenal from access consciousness; distinguish sentience from sapience in the Bachian sense";
      };
    };
  };

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

    # Only start if the env file (and thus SIGNAL_ACCOUNT) exists
    unitConfig.ConditionPathExists = config.age.secrets.hermes-env.path;

    serviceConfig = {
      Type = "simple";
      User = "hermes";
      Group = "hermes";

      # Read SIGNAL_ACCOUNT from the same agenix secret as hermes
      EnvironmentFile = config.age.secrets.hermes-env.path;

      ExecStart = "${pkgs.bash}/bin/bash -c 'exec ${pkgs-unstable.signal-cli}/bin/signal-cli --config /var/lib/hermes/signal-cli --account \"$SIGNAL_ACCOUNT\" daemon --http 127.0.0.1:${toString net.crisuflix.signalCli.port}'";

      Restart = "always";
      RestartSec = 10;

      # Account data stored alongside hermes state
      StateDirectory = "hermes/signal-cli";
      WorkingDirectory = "/var/lib/hermes/signal-cli";
    };
  };
}
