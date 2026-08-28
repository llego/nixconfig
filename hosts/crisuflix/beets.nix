{pkgs, ...}: let
  # Single runtime config shared by the host CLI and beets-flask.
  # The beets-flask compose stack bind-mounts this to /config/beets/config.yaml.
  beetsConfigPath = "/mnt/illby/appstorage/beets/config.yaml";
  beetsConfigured = pkgs.symlinkJoin {
    name = "beets-configured";
    paths = [pkgs.beets];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/beet --add-flags "--config ${beetsConfigPath}"
    '';
  };
in {
  environment.systemPackages = [beetsConfigured];

  # Keep the runtime config in appstorage so Docker can mount the same file.
  system.activationScripts.beetsConfig = ''
    install -D -m 0644 ${./../../dots/beets/config.yaml} ${beetsConfigPath}
  '';
}
