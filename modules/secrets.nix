{inputs, config, hostname, ...}: {
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
}
