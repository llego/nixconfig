# HANDOFF

Last updated: 2026-07-08 09:00 UTC

## Current State

Headscale OIDC + Headplane deployed on VPS. All four hosts running. Crisuflix, laptop, VPS, and rpi5 Tailscale are now declarative with agenix Headscale preauth keys. Crisuflix registers as node `13` / `100.64.0.1` and advertises approved routes for `192.168.1.0/24` and `192.168.3.0/24`; laptop registers as node `14` / `100.64.0.3` and accepts routes; VPS registers as node `15` / `100.64.0.4` and accepts routes; rpi5 registers as node `16` / `100.64.0.5` and accepts routes. Headscale split DNS routes `llego.me.` to a VPS `dnsmasq` responder on `100.64.0.4`, which answers `*.llego.me` as crisuflix `100.64.0.1` for tailnet clients. Key services: OpenCloud 7.0.0 + Collabora (OIDC via Authelia), Homepage dashboard (NixOS service), restic backups (Hetzner), traefik-kop routing, Headscale OIDC via Authelia, Headplane Web UI. Traefik dashboard exposed at `https://traefik.cri.su` with Authelia protection.

NFS on crisuflix is tailnet-wide and firewall-scoped to `tailscale0`: `/mnt/veckjarvi/media`, `/mnt/veckjarvi/backups/haos-backup`, and `/mnt/illby/docker` are exported to `100.64.0.0/10`. Crisuflix has been rebuilt and switched with this config. Laptop config now mounts media and docker via `crisuflix.tailnet.cri.su`, but laptop still needs to be rebuilt to activate the client mount changes.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

Podman migration analysis drafted in `docs/podman-migration-analysis.md`. Current direction: migrate only currently running Docker stacks, prefer rootless Podman under `apps` for ordinary app containers, use `/mnt/illby/podman` for migrated Dockge/stacks config, and keep hardware/network-admin/socket/rootful exceptions explicit rather than forcing everything into one rootless socket scope.

## Architecture Principles

- For a Docker-to-Podman migration on crisuflix, treat rootless Podman as per-user socket scope. Dockge, Traefik discovery, `traefik-kop`, Homepage discovery, Dozzle, and Watchtower must read the same Podman socket as the containers they manage/discover.
- Prefer rootless `apps` containers for ordinary services; keep Frigate, WireGuard/SABnzbd network namespace, and ZFS administration as rootful exceptions unless redesigned and tested.
- Do not migrate inactive compose stacks by default; only currently running services are in scope unless explicitly revived.
- Keep crisuflix NFS access tailnet-first: exports target `100.64.0.0/10`, and NFS firewall ports are opened on `tailscale0` rather than globally/LAN-wide.

## Top 3 Next Actions

- Rebuild laptop so `/mnt/crisuflix-media` and `/mnt/crisuflix-docker` use `crisuflix.tailnet.cri.su`.
- Verify laptop mounts with `findmnt /mnt/crisuflix-media /mnt/crisuflix-docker` and read/write checks.
- If needed, update GUI bookmarks or scripts that still reference `crisuflix.home`.

## Blockers

None.
