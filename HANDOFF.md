# HANDOFF

Last updated: 2026-06-23 15:28 UTC

## Current State

Headscale OIDC + Headplane deployed on VPS. All four hosts running. Crisuflix, laptop, VPS, and rpi5 Tailscale are now declarative with agenix Headscale preauth keys. Crisuflix registers as node `13` / `100.64.0.1` and advertises approved routes for `192.168.1.0/24` and `192.168.3.0/24`; laptop registers as node `14` / `100.64.0.3` and accepts routes; VPS registers as node `15` / `100.64.0.4` and accepts routes; rpi5 registers as node `16` / `100.64.0.5` and accepts routes. Headscale split DNS routes `llego.me.` to a VPS `dnsmasq` responder on `100.64.0.4`, which answers `*.llego.me` as crisuflix `100.64.0.1` for tailnet clients. Key services: OpenCloud 7.0.0 + Collabora (OIDC via Authelia), Homepage dashboard (NixOS service), restic backups (Hetzner), traefik-kop routing, Headscale OIDC via Authelia, Headplane Web UI. Traefik dashboard exposed at `https://traefik.cri.su` with Authelia protection.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

### Headplane

- URL: `https://headplane.cri.su/admin/login`
- Version: 0.7.0-beta.4 (from headplane flake input, via overlay)
- Auth: OIDC via Authelia (shared client with Headscale for perfect subject matching)
- Agent: disabled (no pre-auth key needed)
- Config strict mode: disabled (NixOS-generated config is read-only)
- Runs as `headscale` user on port 8086
- nixpkgs 26.05 has `services.headplane` module + `pkgs.headplane` 0.6.2 — keeping flake overlay for 0.7.0-beta.4 (OIDC fixes in 0.7.0 are needed)

### Infrastructure

- Traefik-kop: crisuflix Docker containers self-register via labels → Redis on VPS → Traefik public routing
- Native NixOS services (HA, Glances, OpenCloud, Collabora, Homepage) use static Traefik routes in `hosts/vps/networking.nix`
- Authelia on VPS (`auth.cri.su`) guards both hosts via forward-auth middleware
- Tailnet DNS for `*.llego.me`: Headscale split DNS sends `llego.me.` to VPS `dnsmasq` (`100.64.0.4` on `tailscale0`); `dnsmasq` answers the zone with crisuflix `100.64.0.1`.

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
- **Session memory via `HANDOFF.md`.** Single file at project root.

## Pending: Declarative Tailscale + Subnet Routing

**Goal:** All tailscale nodes should be fully declarative using headscale pre-auth keys, with crisuflix as subnet router for both LANs.

**Why it matters:** The NixOS `services.tailscale.extraUpFlags` only works when `authKeyFile` is set. Currently all nodes use manual `tailscale up` — flags are lost on rebuilds.

**What needs to happen:**
1. Generate reusable pre-auth keys per host via `sudo headscale preauthkeys create --user <numeric-user-id> --reusable --expiration 87600h --output json`, then store only the JSON `.key` value in agenix.
2. Store each key as an agenix secret (owned by root on the target host)
3. Per-host tailscale config:
   - **crisuflix**: `authKeyFile` + `extraUpFlags = [ "--advertise-routes=192.168.1.0/24,192.168.3.0/24" ]`
   - **laptop/vps/rpi5**: `authKeyFile` + `extraUpFlags = [ "--accept-routes" ]`
4. On first deploy with authKeyFile, wipe `/var/lib/tailscale/tailscaled.state` on each host to trigger re-auth via the autoconnect service
5. Approve subnet routes: `sudo headscale nodes approve-routes --identifier <crisuflix-node-id>`

**Current state of this work:** Complete for all NixOS hosts. `secrets/tailscale-preauth-{crisuflix,laptop,vps,rpi5}.age` are wired via `authKeyFile`, `--login-server=https://headscale.cri.su` is included in global Tailscale up flags, crisuflix uses `useRoutingFeatures = "both"`, and Headscale node `13` has approved routes for `192.168.1.0/24` and `192.168.3.0/24`.

## Top 3 Next Actions

1. **Remove Storj backups** — overdue. Remove Storj services from `modules/restic-backup.nix`, remove `restic-storj-password.age` and `storj-s3-credentials.age` from `secrets/`, delete Storj buckets, rebuild crisuflix.

2. **Commit rpi5 declarative Tailscale** — rpi5 was re-enrolled as Headscale node `16` / `100.64.0.5`; commit `hosts/rpi5/default.nix`, `modules/core/agenix.nix`, `secrets.nix`, `secrets/tailscale-preauth-rpi5.age`, and this handoff update if desired.

3. **Stabilize tailnet DNS IPs** — The `llego.me.` split DNS responder currently depends on VPS `100.64.0.4` and crisuflix `100.64.0.1`. If VPS is re-enrolled with a new tailnet IP again, update `hosts/vps/headscale.nix`.

## Blockers

None.
