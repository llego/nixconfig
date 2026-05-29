# HANDOFF

Last updated: 2026-05-29 18:00 UTC

## Current State

System stable. All four hosts running. Key services: OpenCloud + Collabora (OIDC via Authelia), Homepage dashboard (NixOS service), restic backups (Hetzner), traefik-kop routing.

### Hosts

- **laptop**: daily driver, Niri WM, Intel GPU, NFS mounts, Tailscale, LUKS passphrase-only
- **vps** (`christiansandberg.fi`): Traefik + Redis + Authelia + Gotify + Uptime Kuma + static site
- **crisuflix**: NAS, ZFS, Docker, restic backups
  | Service | URL | Notes |
  |---------|-----|-------|
  | Homepage | `cri.su` | NixOS `services.homepage-dashboard`, port 3000 |
  | Home Assistant | `ha.cri.su` | NixOS `virtualisation.oci-containers` |
  | OpenCloud | `cloud.cri.su` | NixOS service, port 9200, OIDC via Authelia |
  | Collabora | `office.cri.su` | NixOS service, port 9980 |
  | Glances | `glances.cri.su` | NixOS service, port 61208 |
  | Jellyfin | `jellyfin.cri.su` | Docker, port 8096 |
  | Immich | `immich.cri.su` | Docker, port 2283 (bound to Tailscale IP only) |
- **rpi5**: Chromium kiosk, RuuviCollector, nightly reboot

### Infrastructure

- Tailscale mesh: VPS `100.78.37.16`, Crisuflix `100.123.67.48`
- Traefik-kop: crisuflix Docker containers self-register via labels → Redis on VPS → Traefik public routing
- Native NixOS services (HA, Glances, OpenCloud, Collabora, Homepage) use static Traefik routes in `hosts/vps/networking.nix`
- Authelia on VPS (`auth.cri.su`) guards both hosts via forward-auth middleware

### OpenCloud + Collabora

- **Data**: `/mnt/illby/appstorage/opencloud` (ZFS); backup to `crisuflix-opencloud` Hetzner bucket at 04:00
- **Auth**: Authelia OIDC — `OC_EXCLUDE_RUN_SERVICES=idp`, `PROXY_AUTOPROVISION_ACCOUNTS=true`; `llego` has admin role
- **WebDAV**: `https://cloud.cri.su/dav/files/<username>/` — use app passwords for basic auth clients
- **CSP**: `environment.etc."opencloud/csp.yaml"` + `settings.proxy.csp_config_file_location`; run `systemctl restart opencloud` after changes
- **Secrets**: `secrets/opencloud-env.age` (IDM_ADMIN_PASSWORD)

### Homepage Dashboard

- **Module**: `modules/homepage.nix` — `services.homepage-dashboard`, port 3000
- **Docker auto-discover**: socket bind-mounted read-only; `PrivateUsers = lib.mkForce false` + `SupplementaryGroups = ["docker"]` required (DynamicUser blocks supplementary groups otherwise)
- **Widget URLs**: NixOS service has no Docker DNS — compose labels must use `localhost` or host IP, not container names. Immich uses `100.123.67.48:2283` (bound to Tailscale IP only). Fixed in: `arr-stack`, `beszel`, `jellyfin-official`, `immich`
- **Secrets**: `homepage-unifi-password.age` (`HOMEPAGE_VAR_UNIFI_PASSWORD`), `homepage-gotify-key.age` (`HOMEPAGE_VAR_GOTIFY_KEY`) — injected via `environmentFiles`, referenced as `{{HOMEPAGE_VAR_*}}` in config

### Backups (Hetzner Object Storage)

Buckets at `hel1.your-objectstorage.com`: `crisuflix-{bocker,hemmavideon,musik,fotografier,docker,opencloud}` — all running at 04:00 daily.

Storj (legacy) still running in parallel at 03:00 — **remove after 30-day transition** (started ~2026-04, overdue).

### Dotfiles

Managed with hjem-impure from `modules/core/dots/`, symlinked to `~/.config/`. Edit source directly; no rebuild needed. Exception: oh-my-posh uses `environment.etc` (hjem-impure symlinks need live repo path, absent on VPS). Coverage: helix, yazi, niri, kanshi, GTK, noctalia, opencode, beets, SSH shortcuts.

### Laptop LUKS

LUKS2, `allowDiscards`, TPM2 disabled — passphrase-only unlock.

## Architecture Principles

- **No home-manager.** Dotfiles via hjem-impure; source in `modules/core/dots/`.
- **Always build on crisuflix.** All `nixos-rebuild` invocations use `--build-host llego@crisuflix.home`.
- **Two routing tiers.** Docker containers → traefik-kop → Redis → VPS Traefik. Native NixOS services → static routes in `hosts/vps/networking.nix`.
- **Restic on Hetzner.** Secrets: `hetzner-s3-credentials.age`, `restic-hetzner-password.age`.
- **Session memory via `HANDOFF.md`.** Single file at project root.
- **homepage-dashboard needs PrivateUsers override for Docker socket.** `DynamicUser = true` + `PrivateUsers = true` blocks supplementary groups. Add `PrivateUsers = lib.mkForce false` + `SupplementaryGroups = ["docker"]` + `BindReadOnlyPaths = ["/var/run/docker.sock:/var/run/docker.sock"]`.
- **homepage widget URLs must avoid Docker DNS.** Use `localhost:<port>` or host IP. Exception: immich binds only to `100.123.67.48:2283`.
- **Mosquitto ACL requires explicit topic grants.** With `per_listener_settings true`, a user block with no `acl` entries silently denies everything. Always include `acl = ["readwrite #"]` or stricter.
- **OpenCloud CSP via separate file.** `settings.proxy.csp` is silently ignored; use `environment.etc."opencloud/csp.yaml"` + `csp_config_file_location`. Restart service after changes.
- **Collabora SSL termination uses child elements.** `ssl.enable`/`ssl.termination`, not `ssl."@enable"`/`ssl."@termination"` (those set XML attributes, which Collabora ignores).
- **OpenCloud WOPI proof keys disabled.** `COLLABORATION_APP_PROOF_DISABLE=true` required behind a reverse proxy.
- **rclone WebDAV to OpenCloud.** `--webdav-vendor owncloud` for timestamps; `--timeout 0` for large files; `sudo rclone` if files are `apps:apps rw-------`.

### Frigate AI Description on Wallmount

- **Sensor**: `sensor.frigate_terrassen_senaste_beskrivning` — trigger-based MQTT sensor in `templates.yaml`; filters `camera == 'terrassen'`; stores full AI description in attribute `description` (bypasses 255-char `input_text` limit); state is ISO timestamp of last trigger
- **Dashboard**: Wallmount Home tab markdown card (`lovelace.lovelace_wallmount` line ~601) now reads `state_attr(..., 'description')` + timestamp from sensor state
- **Old entities untouched**: `input_text.frigate_latest_object_detection` and `input_datetime.frigate_latest_object_detection_datetime` still updated by separate "Uppdatera wallmount" automation

## Top 3 Next Actions

1. **Remove Storj backups** — overdue. Remove Storj services from `modules/restic-backup.nix`, remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`, delete Storj buckets, rebuild crisuflix.

2. **Deploy adlibris-downloader to laptop** — `nixos-rebuild switch --flake .#laptop`, then configure `~/.config/adlibris-downloader/config` with cookie values from browser DevTools.

3. **Clean up Docker leftovers** — remove `/mnt/illby/docker/stacks/homepage/`, `/mnt/illby/docker/data/homepage/`, and inactive duplicate stacks (`sabnzbd/`, `prowlarr/`, `radarr/`, `sonarr/` — superseded by `arr-stack`).

## Blockers

None.
