# Storj Backup Configuration

This module sets up automated cloud backups to Storj using rclone and systemd timers, replicating the TrueNAS cloudsync functionality.

## Initial Setup

After deploying this configuration, you need to configure rclone with your Storj credentials:

### 1. Get your Storj Access Grant

1. Log into your Storj dashboard: https://www.storj.io/
2. Navigate to Access Management
3. Create an Access Grant or use an existing one
4. Copy the access grant string (it starts with "1...")

### 2. Configure rclone

SSH into crisuflix and run:

```bash
# As root
sudo rclone config

# Follow the prompts:
# n) New remote
# name> storj
# Storage> storj (or the number for Storj)
# access_grant> <paste your access grant here>
# y) Yes this is OK
# q) Quit config
```

Alternatively, manually create `/root/.config/rclone/rclone.conf`:

```ini
[storj]
type = storj
access_grant = your_access_grant_here
```

### 3. Test the connection

```bash
# List buckets
sudo rclone lsd storj:

# Test a small sync (dry-run)
sudo rclone sync /mnt/veckjarvi/media/bocker storj:truenas-versioned/bocker --dry-run --verbose
```

## Backup Schedule

| Service | Source | Destination | Schedule | Mode | Notes |
|---------|--------|-------------|----------|------|-------|
| storj-backup-bocker | /mnt/veckjarvi/media/bocker | truenas-versioned/bocker | Daily 00:00 | sync | Books |
| storj-backup-hemmavideon | /mnt/veckjarvi/hemmavideon | truenas-versioned/hemmavideon | Daily 01:00 | copy | Home videos, excludes gopro folder |
| storj-backup-musik | /mnt/veckjarvi/media/musik | truenas-versioned/musik | Weekly Sun 00:00 | sync | Music |
| storj-backup-fotografier | /mnt/veckjarvi/fotografier/library-new | truenas-versioned/fotografier | Daily 02:30 | sync | Photos |
| storj-backup-docker | /mnt/illby/docker | docker-backup/ | Daily 04:00 | sync | Docker data, excludes jellyfin metadata |

**Modes:**
- `sync`: Make destination identical to source (deletes files not in source)
- `copy`: Copy new/changed files only (never deletes from destination)

## Management Commands

### Check backup status

```bash
# Run the status script
sudo bash /etc/storj-backup-status.sh

# Or check individual services
systemctl status storj-backup-bocker
systemctl status storj-backup-docker
```

### View logs

```bash
# Recent logs from a backup
journalctl -u storj-backup-bocker -n 50

# Follow logs in real-time
journalctl -u storj-backup-docker -f
```

### List timers

```bash
# See all backup timers and when they'll run next
systemctl list-timers 'storj-backup-*'
```

### Manual backup trigger

```bash
# Run a backup immediately (doesn't wait for timer)
sudo systemctl start storj-backup-bocker

# Run with dry-run to preview changes
sudo rclone sync /mnt/veckjarvi/media/bocker storj:truenas-versioned/bocker --dry-run --verbose
```

### Disable/enable a backup

```bash
# Disable a backup timer
sudo systemctl stop storj-backup-musik.timer
sudo systemctl disable storj-backup-musik.timer

# Re-enable
sudo systemctl enable storj-backup-musik.timer
sudo systemctl start storj-backup-musik.timer
```

## Differences from TrueNAS CloudSync

### Advantages
- **Declarative configuration**: Backups defined in version-controlled Nix config
- **Transparent**: Full control over rclone flags and systemd configuration
- **Flexible**: Easy to modify schedules, add flags, or adjust exclusions
- **Integrated logging**: Use standard journalctl for all logs

### Considerations
- **No GUI**: Must use CLI tools for monitoring/management
- **Credential management**: rclone.conf not declaratively managed (contains secrets)
- **Randomized delay**: 5-minute random delay added to timers to avoid exact-time system load spikes

## Troubleshooting

### Backup isn't running

```bash
# Check if timer is active
systemctl list-timers storj-backup-bocker

# Check service status
systemctl status storj-backup-bocker.service
systemctl status storj-backup-bocker.timer

# Enable the timer if disabled
sudo systemctl enable --now storj-backup-bocker.timer
```

### Permission errors

All backups run as root. If you get permission errors:

```bash
# Check ZFS pool permissions
zfs get -r compression,mountpoint,canmount illby veckjarvi

# Check directory permissions
ls -la /mnt/veckjarvi/media/
```

### Rclone errors

```bash
# Test rclone connection
sudo rclone lsd storj:

# Check rclone config
sudo cat /root/.config/rclone/rclone.conf

# Verify access grant is valid (should start with "1...")
```

### High bandwidth usage

If backups are using too much bandwidth:

Edit `/home/llego/nixconfig/modules/storj-backup.nix` and add `--bwlimit` flag:

```nix
ExecStart = "${pkgs.rclone}/bin/rclone sync /path/to/source storj:destination --bwlimit 10M --progress";
```

Then rebuild:

```bash
nixos-rebuild switch --flake .#crisuflix --target-host llego@truenas.home --use-remote-sudo
```

## Security Notes

- rclone config stored at `/root/.config/rclone/rclone.conf` (not version controlled)
- Contains Storj access grant (treat as sensitive credential)
- Only root can read/modify the config
- Consider using agenix or sops-nix for declarative secret management in the future
