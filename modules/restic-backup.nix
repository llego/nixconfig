{
  config,
  pkgs,
  lib,
  ...
}: let
  # Hetzner Object Storage endpoint (Helsinki)
  hetznerS3Endpoint = "https://hel1.your-objectstorage.com";

  # Repository prefix
  repoPrefix = "crisuflix-";

  # Common backup settings
  commonSettings = {
    # Retention policy: keep daily for 30 days, monthly for 12 months
    pruneOpts = [
      "--keep-daily 30"
      "--keep-monthly 12"
    ];

    # Run backup and prune together
    createWrapper = false;

    # All backups run daily at 03:00
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };

  # Hetzner-specific backup settings
  hetznerCommonSettings = {
    inherit (commonSettings) pruneOpts createWrapper;
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
    passwordFile = config.age.secrets.restic-hetzner-password.path;
    environmentFile = "/var/lib/restic/hetzner-s3-credentials";
  };
in {
  # Install restic
  environment.systemPackages = with pkgs; [restic];

  # Restic backup configurations
  services.restic.backups = {
    # Books backup
    bocker-hetzner = {
      repository = "s3:${hetznerS3Endpoint}/${repoPrefix}bocker";
      paths = ["/mnt/veckjarvi/media/bocker"];
      inherit (hetznerCommonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Home videos backup with exclusions
    hemmavideon-hetzner = {
      repository = "s3:${hetznerS3Endpoint}/${repoPrefix}hemmavideon";
      paths = ["/mnt/veckjarvi/hemmavideon"];
      exclude = ["**/2018-03 Sydamerika/gopro"];
      inherit (hetznerCommonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Music backup
    musik-hetzner = {
      repository = "s3:${hetznerS3Endpoint}/${repoPrefix}musik";
      paths = ["/mnt/veckjarvi/media/musik"];
      inherit (hetznerCommonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Photos backup
    fotografier-hetzner = {
      repository = "s3:${hetznerS3Endpoint}/${repoPrefix}fotografier";
      paths = ["/mnt/veckjarvi/fotografier/library-new"];
      inherit (hetznerCommonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Docker backup with exclusions
    docker-hetzner = {
      repository = "s3:${hetznerS3Endpoint}/${repoPrefix}docker";
      paths = ["/mnt/illby/docker"];
      exclude = [
        "**/jellyfin/data/metadata"
        "**/MediaCover"
      ];
      inherit (hetznerCommonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # OpenCloud data backup
    opencloud-hetzner = {
      repository = "s3:${hetznerS3Endpoint}/${repoPrefix}opencloud";
      paths = ["/mnt/illby/appstorage/opencloud"];
      inherit (hetznerCommonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };
  };

  # Ensure restic state directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/restic 0750 root root -"
  ];

  # Optional: Create a script to check backup status
  environment.etc."restic-backup-status.sh" = {
    text = ''
      #!/usr/bin/env bash
      echo "=== Restic Backup Status ==="
      for backup in bocker-hetzner hemmavideon-hetzner musik-hetzner fotografier-hetzner docker-hetzner opencloud-hetzner; do
        echo ""
        echo "Backup: $backup"
        systemctl status "restic-backups-$backup" --no-pager -l | grep -E "(Active:|Loaded:|Main PID:)" || true
        echo "Last run:"
        journalctl -u "restic-backups-$backup" -n 3 --no-pager -o cat | tail -1 || echo "  No logs available"
        echo "Next run:"
        systemctl list-timers "restic-backups-$backup" --no-pager | tail -2 | head -1 || echo "  Timer not active"
      done
    '';
    mode = "0755";
  };
}
