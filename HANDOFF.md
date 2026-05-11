# HANDOFF

Last updated: 2026-05-11 12:15 UTC

## Current State

Dotfile configuration reorganization COMPLETED. Laptop tested and working perfectly. Package installations now co-located with their configurations.

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
- **Dotfile reorganization (2026-05-11) - COMPLETED SUCCESSFULLY**: Moved dotfile configurations to their respective package modules
  - **desktop-environment.nix** now contains: niri, kanshi, GTK, noctalia configs + SSH desktop shortcuts
  - **basic-cli.nix** now contains: helix and yazi configurations  
  - **apps.nix** now contains: opencode configurations
  - **core/hjem.nix** simplified to: core hjem infrastructure + beets config (docker container dependency)
  - Package installations now co-located with their configurations for better maintainability
  - All dotfile symlinks verified working correctly on laptop
  - Single hjem module import in core avoids conflicts

## Architecture Principles

- **No home-manager.** Dotfiles managed with hjem-impure: source in `modules/core/dots/`, symlinked to `~/.config/` via `modules/core/hjem.nix`. Edit source directly; no rebuild needed.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Traefik-kop routing.** VPS runs Traefik + Redis. Crisuflix containers self-register via Docker labels → traefik-kop → Redis. Authelia on VPS guards both hosts. Traffic: User → VPS Traefik → Authelia → crisuflix (Tailscale).
- **Restic on Hetzner.** Buckets at `hel1.your-objectstorage.com`: crisuflix-{bocker,hemmavideon,musik,fotografier,docker}. Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root. No Supermemory plugin.

## Top 3 Next Actions

1. ✅ **Dotfile reorganization FULLY COMPLETED** 
   - All dotfile configs moved to their respective package modules
   - Package installations co-located with configurations for better maintainability
   - hjem.nix simplified to core infrastructure + beets config
   - Laptop tested and verified working correctly
   - Commit 634e665 contains all changes

2. **Remove Storj backups** after 30-day Hetzner transition period (started ~2026-04, check if 30 days have passed)

3. No other active tasks - system fully stable and well-organized

## Blockers

None.
