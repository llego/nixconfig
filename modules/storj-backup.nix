{ config, pkgs, lib, ... }:

{
  # Install rclone for cloud sync
  environment.systemPackages = with pkgs; [ rclone ];

  # Rclone configuration for Storj
  # IMPORTANT: You need to configure rclone manually first:
  # Run as root: rclone config
  # Or place your rclone.conf at /root/.config/rclone/rclone.conf
  # with your Storj credentials
  #
  # For Storj, you'll need:
  # - Access Grant (from Storj dashboard)
  # Configure it like:
  #   [storj]
  #   type = storj
  #   access_grant = <your_access_grant>

  systemd.services = {
    # Task 2: Books backup - daily at 00:00
    "storj-backup-bocker" = {
      description = "Storj backup: Books (/mnt/veckjarvi/media/bocker)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone sync /mnt/veckjarvi/media/bocker storj:truenas-versioned/bocker --progress --stats-one-line --verbose";
        User = "root";
      };
    };

    # Task 3: Home videos backup - daily at 01:00 with exclusions
    "storj-backup-hemmavideon" = {
      description = "Storj backup: Home videos (/mnt/veckjarvi/hemmavideon)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone copy /mnt/veckjarvi/hemmavideon storj:truenas-versioned/hemmavideon --exclude '2018-03 Sydamerika/gopro/**' --progress --stats-one-line --verbose";
        User = "root";
      };
    };

    # Task 4: Music backup - weekly on Sunday at 00:00
    "storj-backup-musik" = {
      description = "Storj backup: Music (/mnt/veckjarvi/media/musik)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone sync /mnt/veckjarvi/media/musik storj:truenas-versioned/musik --progress --stats-one-line --verbose";
        User = "root";
      };
    };

    # Task 7: Photos backup - daily at 02:30
    "storj-backup-fotografier" = {
      description = "Storj backup: Photos (/mnt/veckjarvi/fotografier/library-new)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone sync /mnt/veckjarvi/fotografier/library-new storj:truenas-versioned/fotografier --progress --stats-one-line --verbose";
        User = "root";
      };
    };

    # Task 9: Docker backup - daily at 04:00 with exclusions
    "storj-backup-docker" = {
      description = "Storj backup: Docker (/mnt/illby/docker)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rclone}/bin/rclone sync /mnt/illby/docker storj:docker-backup/ --exclude 'jellyfin/data/metadata/**' --exclude 'MediaCover/**' --progress --stats-one-line --verbose";
        User = "root";
      };
    };
  };

  systemd.timers = {
    # Books backup timer - daily at 00:00
    "storj-backup-bocker" = {
      description = "Timer for Storj books backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Home videos backup timer - daily at 01:00
    "storj-backup-hemmavideon" = {
      description = "Timer for Storj home videos backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 01:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Music backup timer - weekly on Sunday at 00:00
    "storj-backup-musik" = {
      description = "Timer for Storj music backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun *-*-* 00:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Photos backup timer - daily at 02:30
    "storj-backup-fotografier" = {
      description = "Timer for Storj photos backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 02:30:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Docker backup timer - daily at 04:00
    "storj-backup-docker" = {
      description = "Timer for Storj docker backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };

  # Optional: Create a script to check backup status
  environment.etc."storj-backup-status.sh" = {
    text = ''
      #!/usr/bin/env bash
      echo "=== Storj Backup Status ==="
      for service in storj-backup-{bocker,hemmavideon,musik,fotografier,docker}; do
        echo ""
        echo "Service: $service"
        systemctl status "$service" --no-pager -l | grep -E "(Active:|Loaded:|Main PID:)" || true
        echo "Last run:"
        journalctl -u "$service" -n 3 --no-pager -o cat | tail -1 || echo "  No logs available"
        echo "Next run:"
        systemctl list-timers "$service" --no-pager | tail -2 | head -1 || echo "  Timer not active"
      done
    '';
    mode = "0755";
  };
}
