# Restic Backup Configuration

This module sets up automated cloud backups to Storj using restic (via S3 gateway) and the native NixOS `services.restic.backups` module.

## Overview

This is the successor to the `storj-backup.nix` module. It uses restic instead of rclone for better deduplication, compression, and proper snapshot-based backups.

**Key improvements over rclone approach:**
- **Deduplication**: Only transfers changed chunks
- **Compression**: Saves bandwidth and storage
- **Encryption**: All backups are encrypted at rest
- **Snapshots**: Versioned backups with `forget`/`prune` policies
- **Native NixOS integration**: Uses `services.restic.backups`

## Initial Setup

### 1. Create Agenix Secrets

You need to create two encrypted secrets:

**a. Repository password:**
```bash
cd ~/nixconfig
echo "your-strong-password-here" | agenix -e secrets/restic-storj-password.age
```

**b. S3 credentials:**
Create a file with your Storj S3 credentials:
```bash
# Create a temp file with the credentials
cat > /tmp/storj-s3.env << 'EOF'
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
EOF

# Encrypt it
cat /tmp/storj-s3.env | agenix -e secrets/storj-s3-credentials.age

# Clean up temp file
rm /tmp/storj-s3.env
```

### 2. Get Storj S3 Credentials

1. Log into your Storj dashboard: https://storj.io/
2. Go to Access → Create Access Grant
3. Choose "S3 Gateway" credentials
4. Copy the Access Key and Secret Key

### 3. Deploy Configuration

```bash
# Deploy to crisuflix
nixos-rebuild switch --flake .#crisuflix --target-host llego@truenas.home --use-remote-sudo
```

### 4. Initialize Repositories (One-time)

After deployment, initialize each backup repository:

```bash
# SSH into crisuflix
ssh llego@truenas.home

# Initialize all 5 repositories
for repo in bocker hemmavideon musik fotografier docker; do
  sudo restic -r s3:https://gateway.storjshare.io/crisuflix-$repo init
done
```

## Backup Schedule

| Service | Source | Repository | Schedule | Notes |
|---------|--------|------------|----------|-------|
| bocker | /mnt/veckjarvi/media/bocker | crisuflix-bocker | Daily 03:00 | Books |
| hemmavideon | /mnt/veckjarvi/hemmavideon | crisuflix-hemmavideon | Daily 03:00 | Home videos, excludes gopro folder |
| musik | /mnt/veckjarvi/media/musik | crisuflix-musik | Daily 03:00 | Music |
| fotografier | /mnt/veckjarvi/fotografier/library-new | crisuflix-fotografier | Daily 03:00 | Photos |
| docker | /mnt/illby/docker | crisuflix-docker | Daily 03:00 | Docker data, excludes jellyfin metadata |

**Retention Policy:**
- Keep daily snapshots for 30 days
- Keep monthly snapshots for 12 months (1 year)

All backups run concurrently at 03:00 with a 5-minute random delay.

## Management Commands

### Check Backup Status

```bash
# Run the status script
sudo bash /etc/restic-backup-status.sh

# Or check individual services
systemctl status restic-backups-bocker
tail -f /var/log/restic-backups-bocker.log
```

### List Timers

```bash
# See all backup timers and when they'll run next
systemctl list-timers 'restic-backups-*'
```

### View Logs

```bash
# Recent logs from a backup
journalctl -u restic-backups-bocker -n 50

# Follow logs in real-time
journalctl -u restic-backups-bocker -f

# All restic logs
journalctl -u 'restic-backups-*' -f
```

### Manual Backup Trigger

```bash
# Run a backup immediately
sudo systemctl start restic-backups-bocker

# Check the result
sudo systemctl status restic-backups-bocker
```

### List Snapshots

```bash
# List all snapshots in a repository
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker snapshots

# List with details
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker snapshots --verbose
```

### Restore Files

```bash
# Mount a snapshot to browse (read-only)
sudo mkdir -p /mnt/restic-restore
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker mount /mnt/restic-restore
# Browse at /mnt/restic-restore, then umount when done

# Or restore specific files
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker restore latest --target /tmp/restore --include /path/to/file
```

### Disable/Enable a Backup

```bash
# Disable a backup timer
sudo systemctl stop restic-backups-musik.timer
sudo systemctl disable restic-backups-musik.timer

# Re-enable
sudo systemctl enable --now restic-backups-musik.timer
```

## Troubleshooting

### Backup isn't running

```bash
# Check if timer is active
systemctl list-timers restic-backups-bocker

# Check service status
systemctl status restic-backups-bocker.service
systemctl status restic-backups-bocker.timer

# Enable the timer if disabled
sudo systemctl enable --now restic-backups-bocker.timer
```

### Repository not initialized

If you see "Fatal: unable to open repo" errors:

```bash
# Initialize the repository
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker init
```

### Permission errors

All backups run as root with access to the ZFS pools. If you get permission errors:

```bash
# Check ZFS pool permissions
zfs get -r compression,mountpoint,canmount illby veckjarvi

# Check directory permissions
ls -la /mnt/veckjarvi/media/
```

### Storj connection errors

```bash
# Verify S3 credentials file
sudo cat /var/lib/restic/storj-s3-credentials

# Test connection manually
sudo -E restic -r s3:https://gateway.storjshare.io/crisuflix-bocker snapshots
```

### Check disk space

```bash
# Check repository stats
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker stats

# Check what would be pruned (dry-run)
sudo restic -r s3:https://gateway.storjshare.io/crisuflix-bocker forget --keep-daily 30 --keep-monthly 12 --dry-run
```

## Migration from storj-backup.nix

The old rclone-based backups remain in Storj (prefixes: `truenas-versioned/` and `docker-backup/`). This new system:

1. Creates **new repositories** with `crisuflix-` prefix
2. Uses **snapshot-based** backups instead of file sync
3. Provides **automatic versioning** with retention policies

**To clean up old rclone backups (after verifying new backups work):**

```bash
# From Storj dashboard or using rclone
# Delete old buckets: truenas-versioned, docker-backup
```

## Security Notes

- Repository password stored in agenix (`secrets/restic-storj-password.age`)
- S3 credentials stored in agenix (`secrets/storj-s3-credentials.age`)
- All backups are encrypted with AES-256-GCM
- Restic uses authenticated encryption for all data

## Files

- **Module**: `modules/restic-backup.nix`
- **Secrets config**: `modules/agenix.nix` (lines 59-68)
- **Secrets access**: `secrets.nix` (lines 39-40)
- **Host import**: `hosts/crisuflix/default.nix` (line 22)
