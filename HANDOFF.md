# HANDOFF

Last updated: 2026-06-04 07:45 UTC

## Current State

System stable. All four hosts running. Key services: OpenCloud + Collabora (OIDC via Authelia), Homepage dashboard (NixOS service), restic backups (Hetzner), traefik-kop routing.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

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

### Traefik / ACME / DDNS

**crisuflix (Docker)** — `traefik:v3` in `/mnt/illby/docker/stacks/traefik/`
- Label constraint: `traefik.instance=internal` — only picks up containers labelled `internal`
- Containers with `traefik.instance=public` route via traefik-kop → VPS Traefik instead
- DNS-01 via Hetzner Cloud API (`HETZNER_API_TOKEN` in `.env`)
- Single wildcard cert: `llego.me` + `*.llego.me`
- `LEGO_DISABLE_CNAME_SUPPORT=true` to prevent lego CNAME-following issues

**VPS (NixOS)** — `services.traefik` in `hosts/vps/networking.nix`
- Two DNS-01 resolvers: `hetzner` (all Hetzner-hosted zones) + `desec` (`csandberg.consulting`)
- `myresolver` aliased to `hetzner` for traefik-kop redis router compatibility
- Wildcard certs: `*.cri.su`, `*.christiansandberg.fi`, `*.sandbergs.fi`, `*.crisusandberg.fi`, `*.csandberg.fi`, `*.csandberg.consulting`
- `LEGO_DISABLE_CNAME_SUPPORT=true` via `environmentFiles`
- `rootKey = "traefik"` in Redis provider — matches the key prefix traefik-kop writes under

**DDNS (VPS)** — `systemd.services.hetzner-ddns` timer (every 5 min)
- Updates A `@` record for all 5 VPS zones via Hetzner Cloud API delete+recreate rrset pattern
- Caches last IP per zone in `/var/lib/hetzner-ddns/<zone>.ip`
- Token from agenix secret `hetzner-dns-token`
- Replaces both EuroDNS `ddclient` (cri.su) and `cloudflare-ddns` service

### Infrastructure

- Tailscale mesh: VPS `100.78.37.16`, Crisuflix `100.123.67.48`
- Traefik-kop: crisuflix Docker containers self-register via labels → Redis on VPS → Traefik public routing
- Native NixOS services (HA, Glances, OpenCloud, Collabora, Homepage) use static Traefik routes in `hosts/vps/networking.nix`
- Authelia on VPS (`auth.cri.su`) guards both hosts via forward-auth middleware

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

## Top 3 Next Actions

1. **Remove Storj backups** — overdue. Remove Storj services from `modules/restic-backup.nix`, remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`, delete Storj buckets, rebuild crisuflix.

2. **Update traefik-kop container labels** — containers on crisuflix with `traefik.instance=public` still publish `certResolver=myresolver` to VPS Traefik via Redis. Currently works via the `myresolver` alias but should be cleaned up to use `certResolver=hetzner` explicitly.

3. **Clean up Docker leftovers** — remove `/mnt/illby/docker/stacks/homepage/`, `/mnt/illby/docker/data/homepage/`, and inactive duplicate stacks (`sabnzbd/`, `prowlarr/`, `radarr/`, `sonarr/` — superseded by `arr-stack`).

## Blockers

None.
