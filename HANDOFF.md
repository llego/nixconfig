# HANDOFF

Last updated: 2026-05-03 21:30 UTC

## Current State

Laptop boot issues resolved by switching to traditional initrd and passphrase-only LUKS. Generation 7 built and ready for testing.

### Hosts
- **laptop**: daily driver, Niri WM, Intel GPU, NFS mounts, Tailscale, LUKS (passphrase-only), kanshi
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

### Laptop LUKS Setup (reverted for reliability)
- LUKS2 with `allowDiscards` and `crypttabExtraOpts = []` (TPM2 disabled)
- Traditional busybox initrd (`boot.initrd.systemd.enable = false`)  
- Install done via nixos-anywhere from crisuflix with `--copy-host-keys`
- ⚠️ **TPM2 disabled** — passphrase-only unlock for maximum reliability

### Recent Configuration Changes
- **Boot reliability fix (2026-05-03)**: Disabled systemd initrd and TPM2 to resolve boot failures
  - Commented out `boot.initrd.systemd.enable = true` in laptop config
  - Removed `tpm2-device=auto` from `crypttabExtraOpts`
  - Generation 7 built with traditional initrd, ready for testing
  - TPM2 slots preserved in LUKS for potential future re-enablement
- **Kanshi migration**: Moved from systemd.tmpfiles.rules to hjem dotfiles management
  - Config now in `modules/core/dots/kanshi/config` (clean, no ownership issues)
  - Startup still via niri: `spawn-at-startup "kanshi"`
  - Follows established dotfiles architecture pattern

## Architecture Principles

- **No home-manager.** Dotfiles managed with hjem-impure: source in `modules/core/dots/`, symlinked to `~/.config/` via `modules/core/hjem.nix`. Edit source directly; no rebuild needed.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Traefik-kop routing.** VPS runs Traefik + Redis. Crisuflix containers self-register via Docker labels → traefik-kop → Redis. Authelia on VPS guards both hosts. Traffic: User → VPS Traefik → Authelia → crisuflix (Tailscale).
- **Restic on Hetzner.** Buckets at `hel1.your-objectstorage.com`: crisuflix-{bocker,hemmavideon,musik,fotografier,docker}. Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root. No Supermemory plugin.

## Top 3 Next Actions

1. **Test generation 7 boot** — verify traditional initrd and passphrase-only LUKS work reliably
   - Reboot and confirm passphrase prompt appears
   - Test multiple boot cycles for consistency
   - If successful, optionally clean up TPM2 LUKS slots

2. **Remove Storj backups** after 30-day Hetzner transition period (started ~2026-04, check if 30 days have passed)

3. No other active tasks

## Blockers

None.
