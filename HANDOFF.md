# HANDOFF

Last updated: 2026-05-25 11:00 UTC

## Current State

System stable. OpenCloud + Collabora configured but not yet deployed to crisuflix.

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
- Symlinked to `~/.config/` via distributed hjem configuration across modules
- **Recent additions**: oh-my-posh config now user-managed (was system-wide)
- Edit source files directly; changes take effect without rebuild
- **Coverage**: helix, yazi, niri, kanshi, GTK, noctalia, opencode, oh-my-posh, beets, SSH shortcuts

### Laptop LUKS Setup (reverted for reliability)
- LUKS2 with `allowDiscards` and `crypttabExtraOpts = []` (TPM2 disabled)
- Traditional busybox initrd (`boot.initrd.systemd.enable = false`)  
- Install done via nixos-anywhere from crisuflix with `--copy-host-keys`
- ⚠️ **TPM2 disabled** — passphrase-only unlock for maximum reliability

### Recent Configuration Changes
- **OpenCloud + Collabora (2026-05-25) - CONFIGURED, NOT YET DEPLOYED**:
  - `modules/opencloud.nix` — new module with both services on crisuflix
  - OpenCloud on `127.0.0.1:9200`, Collabora on `0.0.0.0:9980` (Tailscale-only firewall rule)
  - Domains: `cloud.cri.su` (OpenCloud), `office.cri.su` (Collabora) via VPS Traefik
  - CSP override in `settings.proxy.csp` to allow Collabora iframe embedding (the main gotcha)
  - `COLLABORATION_APP_PROOF_DISABLE=true` in env to avoid WOPI proof key issues
  - Font bind mount at `/usr/share/fonts/collabora` for proper font rendering in Collabora
  - `secrets/opencloud-env.age` — contains `IDM_ADMIN_PASSWORD` (placeholder; set real password before deploy)
  - No Authelia on either route — OpenCloud handles its own auth
  - ⚠️ **Before deploying**: set a real `IDM_ADMIN_PASSWORD` via `agenix -e secrets/opencloud-env.age`
  - ⚠️ **After first deploy**: OpenCloud generates `/etc/opencloud/opencloud.yaml` with internal service secrets; do not wipe `/var/lib/opencloud`
- **Mosquitto ACL fix (2026-05-15) - FIXED**: Frigate↔HA MQTT was broken because Mosquitto 2.x with `per_listener_settings true` silently blocks all pub/sub when an ACL file has only `user mqtt_user` with no `topic` lines. Added `acl = ["readwrite #"]` to `users.mqtt_user` in `modules/home-automation.nix`. Root cause was subtle: clients connected successfully (CONNACK 0) but every publish/subscribe was silently rejected by the ACL plugin.
- **adlibris-downloader (2026-05-13) - IMPLEMENTED**: New TUI script to fetch watermarked EPUBs from Adlibris digital library and rsync them directly to Booklore's bookdrop on crisuflix.
  - `pkgs/adlibris-downloader/` — sub-flake with `writeShellApplication` + shellcheck
  - Phase 1: cookies via `~/.config/adlibris-downloader/config`
  - Phase 2 (TODO): auto-extract from Zen browser's `cookies.sqlite` via `ZEN_PROFILE_PATH` config key
  - Added to `modules/downloaders.nix` (laptop-only)
  - Full flow: Adlibris library scrape → fzf TUI picker → curl EPUB → rsync to `sabnzbd-downloads/complete/books/` → Booklore auto-imports
- **oh-my-posh to hjem dotfiles (2026-05-11) - COMPLETED SUCCESSFULLY**: Moved oh-my-posh config to user-managed dotfiles
  - **Moved**: `modules/core/oh-my-posh-config.json` → `modules/core/dots/oh-my-posh/config.json`
  - **Updated**: zsh to reference `~/.config/oh-my-posh/config.json` instead of system-wide `/etc/` config
  - **Removed**: system-wide config via `environment.etc` - now user-space only
  - **Added**: to hjem dotfiles management in basic-cli.nix for consistency
  - **Enables**: live editing without rebuilds, follows standard user config conventions
  - **Verified**: working correctly, old system config properly removed
- **Dotfile reorganization (2026-05-11) - COMPLETED**: Package installations co-located with configurations
  - All configurations moved to appropriate modules (desktop-environment, basic-cli, apps)
  - hjem.nix simplified to core infrastructure only (+ beets for docker dependency)

## Architecture Principles

- **No home-manager.** Dotfiles managed with hjem-impure: source in `modules/core/dots/`, symlinked to `~/.config/` via `modules/core/hjem.nix`. Edit source directly; no rebuild needed.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Traefik-kop routing.** VPS runs Traefik + Redis. Crisuflix containers self-register via Docker labels → traefik-kop → Redis. Authelia on VPS guards both hosts. Traffic: User → VPS Traefik → Authelia → crisuflix (Tailscale).
- **Restic on Hetzner.** Buckets at `hel1.your-objectstorage.com`: crisuflix-{bocker,hemmavideon,musik,fotografier,docker}. Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root. No Supermemory plugin.
- **Mosquitto ACL requires explicit topic grants.** With `per_listener_settings true`, a `users.<name>` block with no `acl` entries generates an ACL file that silently denies all pub/sub. Always include `acl = ["readwrite #"]` (or more restrictive grants) for each MQTT user.
- **OpenCloud CSP must fully re-declare all directives.** Setting `services.opencloud.settings.proxy.csp` overrides the entire CSP block — there is no merge with defaults. The NixOS module writes `settings.proxy` to `/etc/opencloud/proxy.yaml`; no separate `csp_config_file_location` needed since the whole proxy config lives there.
- **Collabora font rendering requires host bind mount.** Installing fonts in the Nix store is not enough; Collabora reads from `/usr/share/fonts/collabora`. Use `fileSystems."/usr/share/fonts/collabora"` with `fsType = "none"` and `options = ["bind"]`.
- **OpenCloud WOPI proof keys disabled.** `COLLABORATION_APP_PROOF_DISABLE=true` is required to avoid WOPI request rejections when running behind a reverse proxy; proof key validation assumes direct Collabora↔OpenCloud communication without TLS termination in between.

## Top 3 Next Actions

1. **Deploy OpenCloud + Collabora** — before deploying:
   - Set a real admin password: `agenix -e secrets/opencloud-env.age` (replace the placeholder `changeme-set-a-real-password`)
   - Add EuroDNS DNS records for `cloud.cri.su` and `office.cri.su` pointing to the VPS IP
   - Deploy crisuflix: `nixos-rebuild switch --flake .#crisuflix --build-host llego@crisuflix.home --target-host llego@crisuflix.home --sudo`
   - Deploy vps: `nixos-rebuild switch --flake .#vps --build-host llego@crisuflix.home --target-host llego@christiansandberg.fi --sudo`
   - First login at `https://cloud.cri.su` with user `admin` and the password set in the secret

2. **Remove Storj backups** — transition started ~2026-04, 30 days have passed. Remove Storj services from `modules/restic-backup.nix`, remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`, delete Storj buckets, rebuild crisuflix.

3. **Deploy adlibris-downloader to laptop** — run `nixos-rebuild switch --flake .#laptop` from crisuflix, then configure `~/.config/adlibris-downloader/config` with cookie values from browser DevTools (`.adlibrisauth` and `adss` cookies from adlibris.com).

## Blockers

None.
