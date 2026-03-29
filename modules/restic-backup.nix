{
  config,
  pkgs,
  lib,
  ...
}: let
  # In order to initialize a repository on Storj, run this:
  # sudo bash -c 'set -a && source /var/lib/restic/storj-s3-credentials && set +a && restic -r s3:https://gateway.storjshare.io/crisuflix-bocker init --password-file /run/agenix/restic-storj-password'
  #
  # To list snapshots in a repository:
  # sudo bash -c 'set -a && source /var/lib/restic/storj-s3-credentials && set +a && restic -r s3:https://gateway.storjshare.io/crisuflix-bocker --password-file /run/agenix/restic-storj-password snapshots'
  #
  # To mount a repository for browsing:
  # sudo mkdir -p /mnt/restic-bocker
  # sudo bash -c 'set -a && source /var/lib/restic/storj-s3-credentials && set +a && restic -r s3:https://gateway.storjshare.io/crisuflix-bocker --password-file /run/agenix/restic-storj-password mount /mnt/restic-bocker'
  # When done: sudo umount /mnt/restic-bocker
  #
  # S3 endpoint for Storj
  storjS3Endpoint = "https://gateway.storjshare.io";

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

    # Authentication and credentials
    passwordFile = config.age.secrets.restic-storj-password.path;
    environmentFile = "/var/lib/restic/storj-s3-credentials";
  };
in {
  # Install restic
  environment.systemPackages = with pkgs; [restic];

  # Restic backup configurations
  services.restic.backups = {
    # Books backup
    bocker = {
      repository = "s3:${storjS3Endpoint}/${repoPrefix}bocker";
      paths = ["/mnt/veckjarvi/media/bocker"];
      inherit (commonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Home videos backup with exclusions
    hemmavideon = {
      repository = "s3:${storjS3Endpoint}/${repoPrefix}hemmavideon";
      paths = ["/mnt/veckjarvi/hemmavideon"];
      exclude = ["**/2018-03 Sydamerika/gopro"];
      inherit (commonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Music backup
    musik = {
      repository = "s3:${storjS3Endpoint}/${repoPrefix}musik";
      paths = ["/mnt/veckjarvi/media/musik"];
      inherit (commonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Photos backup
    fotografier = {
      repository = "s3:${storjS3Endpoint}/${repoPrefix}fotografier";
      paths = ["/mnt/veckjarvi/fotografier/library-new"];
      inherit (commonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
    };

    # Docker backup with exclusions
    docker = {
      repository = "s3:${storjS3Endpoint}/${repoPrefix}docker";
      paths = ["/mnt/illby/docker"];
      exclude = [
        "**/jellyfin/data/metadata"
        "**/MediaCover"
      ];
      inherit (commonSettings) pruneOpts createWrapper timerConfig passwordFile environmentFile;
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
      for backup in bocker hemmavideon musik fotografier docker; do
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
