# HANDOFF

Last updated: 2026-04-27 17:00 UTC

## Current State

LUKS encryption for laptop configured. Installer ISO ready to build. Awaiting physical reinstall of laptop.

### Hosts
- **laptop**: daily driver, Niri WM, Intel GPU, NFS mounts, Tailscale
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

## Architecture Principles

- **No home-manager.** Dotfiles managed with hjem-impure: source in `modules/core/dots/`, symlinked to `~/.config/` via `modules/core/hjem.nix`. Edit source directly; no rebuild needed.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Traefik-kop routing.** VPS runs Traefik + Redis. Crisuflix containers self-register via Docker labels → traefik-kop → Redis. Authelia on VPS guards both hosts. Traffic: User → VPS Traefik → Authelia → crisuflix (Tailscale).
- **Restic on Hetzner.** Buckets at `hel1.your-objectstorage.com`: crisuflix-{bocker,hemmavideon,musik,fotografier,docker}. Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root. No Supermemory plugin.

## Top 3 Next Actions

1. **Build and write installer ISO** (on crisuflix):
   ```bash
   cd ~/nixconfig
   nix build --impure .#nixosConfigurations.laptop-installer.config.system.build.isoImage
   sudo dd if=result/iso/*.iso of=/dev/sdi bs=4M status=progress oflag=sync
   ```
2. **Run install on laptop**: boot USB → `run-install` → enter LUKS passphrase → `sudo reboot`
3. **Post-install on laptop** (first boot):
   - Restore SSH keys: `scp -r llego@crisuflix.home:~/laptop-ssh-backup/.ssh ~/`
   - Enroll TPM2: `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2`
   - On crisuflix: `ssh-keyscan laptop.home` → update `secrets/secrets.nix` → `agenix -r` → `nixos-rebuild switch --flake .#laptop --build-host llego@crisuflix.home --target-host llego@laptop.home --sudo`
4. **Remove Storj backups** after 30-day Hetzner transition period (check if ready)

## Blockers

None.
