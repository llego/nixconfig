{
  config,
  lib,
  pkgs,
  ...
}: let
  net = config.networkVars;
  hetznerS3Endpoint = "https://hel1.your-objectstorage.com";
in {
  age.secrets."pocket-id-encryption-key" = {
    owner = config.services.pocket-id.user;
    group = config.services.pocket-id.group;
  };

  services.pocket-id = {
    enable = true;
    credentials = {
      ENCRYPTION_KEY = config.age.secrets."pocket-id-encryption-key".path;
    };
    settings = {
      # <https://pocket-id.org/docs/configuration/environment-variables>
      APP_URL = "https://id.cri.su";
      TRUST_PROXY = true;
      HOST = "127.0.0.1";
      PORT = net.vps.pocketId.port;
    };
  };

  services.restic.backups.pocket-id-hetzner = {
    repository = "s3:${hetznerS3Endpoint}/vps-pocket-id";
    command = [
      "${pkgs.writeShellScript "pocket-id-export" ''
        export ENCRYPTION_KEY="$(${config.systemd.package}/bin/systemd-creds cat ENCRYPTION_KEY_FILE)"
        exec ${lib.getExe config.services.pocket-id.package} export --path -
      ''}"
    ];
    extraBackupArgs = ["--stdin-filename pocket-id-export.zip"];
    passwordFile = config.age.secrets.restic-hetzner-password.path;
    environmentFile = config.age.secrets.hetzner-s3-credentials.path;
    initialize = true;
    pruneOpts = ["--keep-daily 30" "--keep-monthly 12"];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };

  # Export uses the same relative data paths, settings and credentials as the server.
  systemd.services.restic-backups-pocket-id-hetzner.serviceConfig = {
    WorkingDirectory = config.services.pocket-id.dataDir;
    EnvironmentFile = lib.mkAfter config.systemd.services.pocket-id.serviceConfig.EnvironmentFile;
    LoadCredential = config.systemd.services.pocket-id.serviceConfig.LoadCredential;
    UMask = "0077";
  };

  systemd.tmpfiles.rules = ["d /var/lib/restic 0750 root root -"];

  services.traefik.dynamicConfigOptions.http = {
    routers.pocket-id = {
      rule = "Host(`id.cri.su`)";
      entryPoints = ["websecure"];
      service = "pocket-id";
      tls.certResolver = "hetzner";
    };

    services.pocket-id.loadBalancer.servers = [
      {
        url = "http://127.0.0.1:${toString net.vps.pocketId.port}";
      }
    ];
  };
}
