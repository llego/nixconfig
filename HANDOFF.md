# HANDOFF

Last updated: 2026-04-30 12:00 UTC

## Current State

Laptop LUKS encryption reinstall completed successfully. TPM2 basic enrollment active. Currently implementing TPM2+PIN protection.

### Hosts
- **laptop**: daily driver, Niri WM, Intel GPU, NFS mounts, Tailscale — **LUKS reinstall completed**
- **vps** (`christiansandberg.fi`): Traefik + Redis + Authelia + Gotify + Uptime Kuma + static site
- **crisuflix**: NAS, ZFS, Docker, Home Assistant, Music Assistant, ESPHome, Mosquitto, restic backups
- **rpi5**: Chromium kiosk, RuuviCollector, nightly reboot

### Infrastructure
- Tailscale mesh: VPS `100.78.37.16`, Crisuflix `100.123.67.48`
- Traefik-kop: containers on crisuflix publish routes via Docker labels → Redis on VPS → Traefik routes public traffic
- Authelia on VPS protects services on both hosts via forward-auth middleware

### Backup State
- **Dual parallel backup system** running during 30-day transition period:
  - Storj (legacy): 5 jobs at 03:00 daily — bocker, hemmavideon, musik, fotografier, docker
  - Hetzner Object Storage (new): 5 jobs at 04:00 daily — same datasets
- Transition started ~2026-04. After 30 days, remove Storj entirely.

### Dotfiles
- Managed with hjem-impure from `modules/core/dots/`
- Symlinked to `~/.config/` via `modules/core/hjem.nix`
- Edit source files directly; changes take effect without rebuild

### Laptop LUKS Setup (completed)
- LUKS2 with `allowDiscards` and `crypttabExtraOpts = ["tpm2-device=auto"]`
- `boot.initrd.systemd.enable = true` for TPM2 unlock support
- Install done via nixos-anywhere from crisuflix with `--copy-host-keys`
- TPM2 enrollment pending: `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2`

### hjem Fix Note
After reinstall, `~/.config` was owned by root (created by systemd.tmpfiles for kanshi). hjem-impure
failed to create symlinks because parent dirs didn't exist. Fix: `sudo chown llego:users ~/.config`,
create missing subdirs, restart `hjem-activate@llego.service`.

## Architecture Principles

- **No home-manager.** Dotfiles managed with hjem-impure: source in `modules/core/dots/`, symlinked to `~/.config/` via `modules/core/hjem.nix`. Edit source directly; no rebuild needed.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Traefik-kop routing.** VPS runs Traefik + Redis. Crisuflix containers self-register via Docker labels → traefik-kop → Redis. Authelia on VPS guards both hosts. Traffic: User → VPS Traefik → Authelia → crisuflix (Tailscale).
- **Restic on Hetzner.** Buckets at `hel1.your-objectstorage.com`: crisuflix-{bocker,hemmavideon,musik,fotografier,docker}. Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root. No Supermemory plugin.

## Top 3 Next Actions

1. **Complete TPM2+PIN setup:** ✅ LUKS reinstall done, implementing 4-digit PIN protection on TPM2 enrollment

2. **Remove Storj backups** after 30-day Hetzner transition period (started ~2026-04, check if 30 days have passed)

3. No other active tasks

## Blockers

None.
