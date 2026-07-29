# HANDOFF

Last updated: 2026-07-29 07:00 UTC

## Current State

Headplane on VPS has been migrated in config from the nixpkgs `services.headplane` module to the upstream pinned `tale/headplane` NixOS module. `hosts/vps/headscale.nix` disables the nixpkgs Headplane module, imports `inputs.headplane.nixosModules.headplane`, uses upstream `headscale.api_key_path`, removes old agent preauth config, and declares `/var/lib/headplane/agent` as `headscale:headscale` via tmpfiles. Local

Docker on crisuflix now waits for Tailscale before starting. `hosts/crisuflix/default.nix` orders `docker.service` after/wants `tailscaled.service` and `tailscaled-set.service`, and adds a `preStart` gate that waits up to 120 seconds for `tailscale ip -4` to return `100.64.0.1`. This prevents Docker from auto-restoring `restart=unless-stopped` containers before local Traefik can bind `100.64.0.1:80/443` and before traefik-kop can use `tailscale0`. Local eval and `nixos-rebuild dry-build --flake .#crisuflix` succeeded. After reboot, `tailscaled.service` is active, `tailscaled-set.service` completed before Docker started, Docker is active, the `traefik` container is bound to `100.64.0.1:80/443`, `traefik-kop` publishes routes using `100.64.0.1`, and `https://ai.cri.su` returns 200.

VPS traefik-kop reboot fix has been simplified in config: `networkVars.hosts.vps` is now the stable tailnet IP `100.64.0.4` and `networkVars.hosts.crisuflix` is now `100.64.0.1`, removing MagicDNS from Redis bind/provider/firewall paths. `hosts/vps/reverse-proxy.nix` now orders Traefik after/wants `redis-traefik.service`. Local eval confirms Redis binds `100.64.0.4`, Traefik uses Redis endpoint `100.64.0.4:6379`, and Traefik wants/starts after `redis-traefik.service`; `nixos-rebuild dry-build --flake .#vps` succeeds. VPS was deployed and rebooted. Runtime recovered without manual restarts: `tailscaled`, `headscale`, `redis-traefik`, and `traefik` are active; Redis listens on `100.64.0.4:6379`; Traefik has Redis-backed routers; crisuflix can reach Redis; `https://ai.cri.su` returns 200; `https://traefik.cri.su` redirects to Authelia. Boot logs still show Redis initially failed with `bind: Cannot assign requested address` until Tailscale acquired `100.64.0.4`, so add a simple Redis `preStart` gate if clean boot logs/no temporary outage are desired.

NFS on crisuflix is tailnet-wide and firewall-scoped to `tailscale0`: `/mnt/veckjarvi/media`, `/mnt/veckjarvi/backups/haos-backup`, and `/mnt/illby/docker` are exported to `100.64.0.0/10`. Parent exports for media and docker use `crossmnt` so child ZFS datasets are visible. Laptop mounts media and docker via `crisuflix.tailnet.cri.su` using NFSv4.2; both crisuflix and laptop have been rebuilt and switched, and `/mnt/crisuflix-media` plus `/mnt/crisuflix-docker` are verified active on laptop.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

Shared core Nix settings now trust the personal Cachix cache `https://llego.cachix.org` with public key `llego.cachix.org-1:WzO82OCKQr+mNapPewBwEeN5Ui5vPjduTIYfrD0YFwQ=`. Laptop eval confirms the substituter and key are present. The built `album-downloader` and `bandsnatch` outputs were pushed to Cachix and their narinfo entries were verified, so matching laptop rebuilds should substitute them instead of compiling Rust locally.

## Top 3 Next Actions

- Rebuild laptop with the committed Cachix settings and confirm `album-downloader`/`bandsnatch` substitute from `llego.cachix.org`.

## Blockers
