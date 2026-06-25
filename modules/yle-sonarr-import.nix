{
  config,
  inputs,
  pkgs,
  ...
}: let
  importer = inputs.yle-sonarr-import.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  systemd.services.yle-sonarr-import = {
    description = "Download mapped YLE episodes and ask Sonarr to import them";
    after = ["network-online.target" "docker.service"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = config.age.secrets.yle-sonarr-import-env.path;
    path = [
      pkgs.yle-dl
      pkgs.ffmpeg
    ];
    environment = {
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "apps";
      Group = "apps";
      StateDirectory = "yle-sonarr-import";
      EnvironmentFile = [
        config.age.secrets.yle-sonarr-import-env.path
      ];
      ExecStart = "${importer}/bin/yle-sonarr-import";
    };
  };

  systemd.timers.yle-sonarr-import = {
    description = "Daily YLE Sonarr import";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 06:30:00";
      Persistent = true;
      RandomizedDelaySec = "20m";
    };
  };
}
