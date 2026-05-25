# HANDOFF

Last updated: 2026-05-25 20:00 UTC

## Current State

System stable. OpenCloud + Collabora fully deployed and working on crisuflix. Authelia OIDC login working. SFTPGo → OpenCloud file migration complete.

### Hosts
- **laptop**: daily driver, Niri WM, Intel GPU, NFS mounts, Tailscale, LUKS (passphrase-only), kanshi
- **vps** (`christiansandberg.fi`): Traefik + Redis + Authelia + Gotify + Uptime Kuma + static site
- **crisuflix**: NAS, ZFS, Docker, Home Assistant, Music Assistant, ESPHome, Mosquitto, restic backups, OpenCloud, Collabora
- **rpi5**: Chromium kiosk, RuuviCollector, nightly reboot

### Infrastructure
- Tailscale mesh: VPS `100.78.37.16`, Crisuflix `100.123.67.48`
- Traefik-kop: containers on crisuflix publish routes via Docker labels → Redis on VPS → Traefik routes public traffic
- Authelia on VPS protects services on both hosts via forward-auth middleware

### OpenCloud + Collabora (deployed 2026-05-25)
- **OpenCloud**: `cloud.cri.su` → crisuflix `100.123.67.48:9200` via VPS Traefik
- **Collabora**: `office.cri.su` → crisuflix `0.0.0.0:9980` (Tailscale-only firewall rule)
- **Data**: `/mnt/illby/appstorage/opencloud` (ZFS on illby pool)
- **Backup**: `restic-backups-opencloud-hetzner.timer` → `crisuflix-opencloud` bucket at Hetzner hel1
  - ⚠️ Bucket must be created in Hetzner console and repo initialized before first backup runs
  - Init: `sudo bash -c 'set -a && source /var/lib/restic/hetzner-s3-credentials && set +a && restic -r s3:https://hel1.your-objectstorage.com/crisuflix-opencloud init --password-file /run/agenix/restic-hetzner-password'`
- **Auth**: Authelia OIDC (`auth.cri.su`) — built-in IDP excluded (`OC_EXCLUDE_RUN_SERVICES=idp`) — **working**
- **User mapping**: Authelia `preferred_username` → OpenCloud `username`; `llego` user has admin role
- **Auto-provision**: new Authelia users get OpenCloud `user` role on first login
- **WebDAV**: working at `https://cloud.cri.su/dav/files/<username>/` — use app passwords for basic auth clients
- **Collabora**: working — documents open and edit correctly
- **Secrets**: `secrets/opencloud-env.age` — contains `IDM_ADMIN_PASSWORD`
- **CSP**: managed via `/etc/opencloud/csp.yaml` (written by `environment.etc`); `csp_config_file_location` points proxy there; requires `systemctl restart opencloud` when changed (not auto-restarted on `environment.etc` changes)
- **File migration**: SFTPGo → OpenCloud completed 2026-05-25 via rclone WebDAV (878 files, ~2.7 GiB, timestamps preserved)

### Backup State
- **Dual parallel backup system** running during 30-day transition period:
  - Storj (legacy): 5 jobs at 03:00 daily — bocker, hemmavideon, musik, fotografier, docker
  - Hetzner Object Storage (new): 6 jobs at 04:00 daily — same datasets + opencloud
- Transition started ~2026-04. After 30 days, remove Storj entirely.

### Dotfiles
- Managed with hjem-impure from `modules/core/dots/`
- Symlinked to `~/.config/` via distributed hjem configuration across modules
- oh-my-posh config reverted to `environment.etc` (system-wide) — hjem-impure symlinks the live repo path which doesn't exist on VPS
- Edit source files directly; changes take effect without rebuild (except oh-my-posh)
- **Coverage**: helix, yazi, niri, kanshi, GTK, noctalia, opencode, beets, SSH shortcuts

### Laptop LUKS Setup (reverted for reliability)
- LUKS2 with `allowDiscards` and `crypttabExtraOpts = []` (TPM2 disabled)
- Traditional busybox initrd (`boot.initrd.systemd.enable = false`)
- Install done via nixos-anywhere from crisuflix with `--copy-host-keys`
- ⚠️ **TPM2 disabled** — passphrase-only unlock for maximum reliability

### Recent Configuration Changes
- **OpenCloud Authelia OIDC (2026-05-25) - WORKING**:
  - 4 Authelia OIDC clients added (`web`, `OpenCloudDesktop`, `OpenCloudAndroid`, `OpenCloudIOS`) — all public PKCE, `two_factor` policy
  - `opencloud` claims policy added to Authelia — includes `groups` in id_token
  - OpenCloud env: `OC_OIDC_ISSUER=https://auth.cri.su`, `OC_EXCLUDE_RUN_SERVICES=idp`, `PROXY_AUTOPROVISION_ACCOUNTS=true`, `PROXY_ROLE_ASSIGNMENT_DRIVER=default`
  - CSP `connect-src` and `frame-src` updated to include `https://auth.cri.su` and `wss://auth.cri.su`
  - ⚠️ After `csp.yaml` changes, must `sudo systemctl restart opencloud` on crisuflix (not auto-restarted)
- **SFTPGo → OpenCloud migration (2026-05-25) - COMPLETE**: All files migrated via rclone WebDAV
  - 878 files, ~2.7 GiB; timestamps preserved via `--webdav-vendor owncloud` (`X-OC-Mtime` headers)
  - Large files (>~500MB) needed `--timeout 0` to avoid OpenCloud's 60s internal PUT timeout
  - Files owned by `apps:apps` with `rw-------` needed root to read — use `sudo rclone` or fix perms first
  - SFTPGo data at `/mnt/illby/docker/data/sftpgo/data/data/llego/` is untouched
- **OpenCloud CSP fix (2026-05-25)**: Moved CSP from `settings.proxy.csp` (silently ignored) to `environment.etc."opencloud/csp.yaml"` + `settings.proxy.csp_config_file_location`. The `csp` key is not a valid proxy YAML schema key — only `csp_config_file_location` works.
- **Collabora SSL fix (2026-05-25)**: Must use `ssl.enable = false` / `ssl.termination = true` (child elements), NOT `ssl."@enable"` / `ssl."@termination"` (XML attributes). Collabora reads child elements; attributes are ignored.
- **Collabora server_name (2026-05-25)**: Must set `settings.server_name = "office.cri.su:443"` or discovery advertises `https://127.0.0.1:9980` and browsers cannot connect.
- **OpenCloud bind address (2026-05-25)**: Must bind to `net.hosts.crisuflix` (Tailscale IP), not `127.0.0.1`, so VPS Traefik can reach it.
- **OpenCloud stateDir (2026-05-25)**: Data stored at `/mnt/illby/appstorage/opencloud` (ZFS).
- **oh-my-posh reverted to environment.etc (2026-05-25)**: hjem-impure symlinks point to live repo path which doesn't exist on VPS. Reverted to `environment.etc."oh-my-posh/config.json"` so VPS builds succeed.
- **Mosquitto ACL fix (2026-05-15) - FIXED**: Frigate↔HA MQTT was broken because Mosquitto 2.x with `per_listener_settings true` silently blocks all pub/sub when an ACL file has only `user mqtt_user` with no `topic` lines. Added `acl = ["readwrite #"]` to `users.mqtt_user` in `modules/home-automation.nix`.
- **adlibris-downloader (2026-05-13) - IMPLEMENTED**: New TUI script to fetch watermarked EPUBs from Adlibris digital library and rsync them directly to Booklore's bookdrop on crisuflix.
  - `pkgs/adlibris-downloader/` — sub-flake with `writeShellApplication` + shellcheck
  - Phase 2 (TODO): auto-extract from Zen browser's `cookies.sqlite` via `ZEN_PROFILE_PATH` config key

## Architecture Principles

- **No home-manager.** Dotfiles managed with hjem-impure: source in `modules/core/dots/`, symlinked to `~/.config/` via `modules/core/hjem.nix`. Edit source directly; no rebuild needed. Exception: oh-my-posh uses `environment.etc` because hjem-impure needs the live repo path which only exists on laptop/crisuflix, not VPS.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Traefik-kop routing.** VPS runs Traefik + Redis. Crisuflix containers self-register via Docker labels → traefik-kop → Redis. Authelia on VPS guards both hosts. Traffic: User → VPS Traefik → Authelia → crisuflix (Tailscale).
- **Restic on Hetzner.** Buckets at `hel1.your-objectstorage.com`: crisuflix-{bocker,hemmavideon,musik,fotografier,docker,opencloud}. Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root. No Supermemory plugin.
- **Mosquitto ACL requires explicit topic grants.** With `per_listener_settings true`, a `users.<name>` block with no `acl` entries generates an ACL file that silently denies all pub/sub. Always include `acl = ["readwrite #"]` (or more restrictive grants) for each MQTT user.
- **OpenCloud CSP via separate file.** The `csp` key under `settings.proxy` is not a valid proxy YAML schema key and is silently ignored. Use `environment.etc."opencloud/csp.yaml"` + `settings.proxy.csp_config_file_location = "/etc/opencloud/csp.yaml"`. After changing csp.yaml, run `systemctl restart opencloud` (environment.etc changes don't trigger service restarts).
- **Collabora SSL termination requires child elements.** Use `ssl.enable = false` / `ssl.termination = true`, not `ssl."@enable"` / `ssl."@termination"`. The `@` prefix sets XML attributes; Collabora reads the child `<enable>` and `<termination>` elements.
- **Collabora font rendering requires host bind mount.** Installing fonts in the Nix store is not enough; Collabora reads from `/usr/share/fonts/collabora`. Use `fileSystems."/usr/share/fonts/collabora"` with `fsType = "none"` and `options = ["bind"]`.
- **OpenCloud WOPI proof keys disabled.** `COLLABORATION_APP_PROOF_DISABLE=true` is required to avoid WOPI request rejections when running behind a reverse proxy.
- **OpenCloud CSP must include auth domain.** When using an external OIDC provider, `connect-src` and `frame-src` must include the provider's domain (e.g. `https://auth.cri.su`) or the browser's OIDC client silently hangs.
- **rclone WebDAV migration to OpenCloud.** Use `--webdav-vendor owncloud` for timestamp preservation (`X-OC-Mtime`). Use `--timeout 0` for large files. App passwords work for basic auth; generate in OpenCloud web UI → Settings → Security → App passwords. For files inaccessible due to permissions, run rclone with `sudo`. If 409 Conflict on directory upload, create the directory first via `curl -u user:pass -X MKCOL <url>`.

## Top 3 Next Actions

1. **Remove Storj backups** — transition started ~2026-04, 30 days have passed. Remove Storj services from `modules/restic-backup.nix`, remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`, delete Storj buckets, rebuild crisuflix.

2. **Initialize Hetzner opencloud backup bucket** — create `crisuflix-opencloud` bucket in Hetzner Object Storage console (hel1 region), then run restic init command on crisuflix (see OpenCloud section above).

3. **Clean up old admin user in OpenCloud** — the built-in `admin` account (created during first init) is now orphaned since auth is via Authelia. Can be deleted via Graph API: `curl -X DELETE -u REDACTED_BASIC_AUTH https://cloud.cri.su/graph/v1.0/users/<admin-user-id>`.

## Blockers

None.
