# AGENTS

### Session Start

Read in this exact order:
1. `README.md`
2. `HANDOFF.md`

### During Work

- Keep `HANDOFF.md` aligned with current status and next actions.
- Record durable decisions in the `Architecture Principles` section of `HANDOFF.md`.
- Update `HANDOFF.md` mid-session if significant decisions are made.

### Session End

- Update `HANDOFF.md`:
  - `Last updated` timestamp (`YYYY-MM-DD HH:MM UTC`)
  - current state
  - top 3 next actions
  - blockers (if any)
- Confirm no secrets were added to tracked files.

## Restic Backups (crisuflix)

Hetzner at 04:00, Storj (legacy, being phased out) at 03:00. Both run as systemd services.

```bash
ssh llego@crisuflix.home systemctl status 'restic-backup-*.service'
ssh llego@crisuflix.home sudo restic -r s3:hel1.your-objectstorage.com/crisuflix-<name> snapshots
```

Storj removal checklist (after 30-day Hetzner transition — see `HANDOFF.md`):
- Remove Storj services from `modules/restic-backup.nix`
- Remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`
- Delete Storj buckets and close Storj account
- Rebuild crisuflix
