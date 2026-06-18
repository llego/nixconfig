# HANDOFF

Last updated: 2026-06-17 21:30 UTC

## Current State

Headscale OIDC + Headplane deployed on VPS. All four hosts running. Key services: OpenCloud 7.0.0 + Collabora (OIDC via Authelia), Homepage dashboard (NixOS service), restic backups (Hetzner), traefik-kop routing, Headscale OIDC via Authelia, Headplane Web UI. Traefik dashboard exposed at `https://traefik.cri.su` with Authelia protection.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

### Headscale OIDC

Headscale now authenticates via Authelia OIDC (shared client `headscale` with Headplane):
- Issuer: `https://auth.cri.su`
- Client ID: `headscale`
- PKCE enabled (S256)
- Scopes: `openid`, `profile`, `email`, `groups`
- Authelia `claims_policy: headscale` with `id_token: ['email', 'groups']` (workaround for Headscale's OIDC claims hydration bug)
- Redirect URIs: `https://headscale.cri.su/oidc/callback`, `https://headplane.cri.su/admin/oidc/callback`

**User migration note:** Existing local Headscale user `llego` has no email set. OIDC logins will create a new user record. Email matching won't work until email is set on the local user. First OIDC login will prompt for manual Headscale user selection.

### Headplane

- URL: `https://headplane.cri.su/admin/login`
- Version: 0.7.0-beta.4 (from headplane flake input, via overlay)
- Auth: OIDC via Authelia (shared client with Headscale for perfect subject matching)
- Agent: disabled (no pre-auth key needed)
- Config strict mode: disabled (NixOS-generated config is read-only)
- Runs as `headscale` user on port 8086
- nixpkgs 26.05 has `services.headplane` module + `pkgs.headplane` 0.6.2 — keeping flake overlay for 0.7.0-beta.4 (OIDC fixes in 0.7.0 are needed)

### Hosts

- **laptop**: daily driver, Niri WM, Intel GPU, NFS mounts, Tailscale, LUKS passphrase-only
- **vps** (`christiansandberg.fi`): Traefik + Redis + Authelia + Gotify + Uptime Kuma + static site + Headscale (OIDC) + Headplane
- **crisuflix**: NAS, ZFS, Docker, restic backups
  | Service | URL | Notes |
  |---------|-----|-------|
  | Homepage | `cri.su` | NixOS `services.homepage-dashboard`, port 3000 |
  | Home Assistant | `ha.cri.su` | NixOS `virtualisation.oci-containers` |
  | Music Assistant | `ma.cri.su` | NixOS `services.music-assistant`, port 8095 |
  | OpenCloud | `cloud.cri.su` | NixOS service, port 9200, OIDC via Authelia |
  | Collabora | `office.cri.su` | NixOS service, port 9980 |
  | Glances | `glances.cri.su` | NixOS service, port 61208 |
  | Jellyfin | `jellyfin.cri.su` | Docker, port 8096 |
  | Immich | `immich.cri.su` | Docker, port 2283 (bound to Tailscale IP only) |
- **rpi5**: Chromium kiosk, nightly reboot — fully working after NixOS 26.05 migration
  - `boot.initrd.systemd.enable = false` required: systemd initrd incompatible with raspberry-pi-nix kernel on 26.05+
  - Display output is `HDMI-A-2`, scale 1.5
  - nixpkgs pinned to `nixos-26.05`; `system.stateVersion` still `"24.11"` (harmless)

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

### Network (crisuflix)

- `br0` (`192.168.1.101/24`) — trusted LAN, gateway `192.168.1.1`
- `br1` (`192.168.3.103/24`) — IoT network
- UniFi: `192.168.3.0/24` is in custom zone (CUSTOM1) — blocks IoT → trusted LAN, allows IoT → WAN
- UniFi: mDNS Proxy enabled on both networks as fallback
- Avahi reflector enabled on crisuflix (`br0` + `br1`) for cross-subnet mDNS (Chromecast, ESPHome, etc.)
- IoT devices reach HA/MQTT/ESPHome via `192.168.3.103` (same-subnet, no firewall rule needed)
- InfluxDB integration: config entry `path` must be `""` (empty) — was `/`, caused 404 on setup

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
- **Fully declarative tailscale.** Prefer `authKeyFile` + `extraUpFlags` over manual `tailscale up`.

## Pending: Declarative Tailscale + Subnet Routing

**Goal:** All tailscale nodes should be fully declarative using headscale pre-auth keys, with crisuflix as subnet router for both LANs.

**Why it matters:** The NixOS `services.tailscale.extraUpFlags` only works when `authKeyFile` is set. Currently all nodes use manual `tailscale up` — flags are lost on rebuilds.

**What needs to happen:**
1. Generate reusable pre-auth keys per host via `sudo headscale preauthkeys --user llego --reusable create`
2. Store each key as an agenix secret (owned by root on the target host)
3. Per-host tailscale config:
   - **crisuflix**: `authKeyFile` + `extraUpFlags = [ "--advertise-routes=192.168.1.0/24,192.168.3.0/24" ]`
   - **laptop/vps/rpi5**: `authKeyFile` + `extraUpFlags = [ "--accept-routes" ]`
4. On first deploy with authKeyFile, wipe `/var/lib/tailscale/tailscaled.state` on each host to trigger re-auth via the autoconnect service
5. Approve subnet routes: `sudo headscale nodes approve-routes --identifier <crisuflix-node-id>`

**Current state of this work:** Config edits made (`modules/core/default.nix` has `--accept-routes`, `hosts/crisuflix/default.nix` has `--advertise-routes`) but flags are silently ignored because no `authKeyFile` is set. No pre-auth keys generated yet.

## Top 3 Next Actions

1. **Set email on existing Headscale user** — Run `sudo headscale users update --email <your-email> --identifier 1` on VPS so OIDC email matching can link your Authelia account to the existing `llego` user. Otherwise first OIDC login will create a new user and you'll need to manually select the Headscale user.

2. **Remove Storj backups** — overdue. Remove Storj services from `modules/restic-backup.nix`, remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`, delete Storj buckets, rebuild crisuflix.

3. **Declarative tailscale + subnet routing** — See "Pending" section above. Generate pre-auth keys, create agenix secrets, set `authKeyFile` per host, wipe tailscale state, approve routes.

## Blockers

None.
