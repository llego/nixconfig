# HANDOFF

Last updated: 2026-07-27 19:24 UTC

## Current State

Host-specific services have been moved under their owning host directories. VPS-owned service/edge configs now live in `hosts/vps/`: `authelia-cri.su.nix`, `christiansandberg-website.nix`, `ddns.nix`, `gotify.nix`, `headscale.nix`, `reverse-proxy.nix`, and `uptime-kuma.nix`. Crisuflix-owned configs now live in `hosts/crisuflix/`: `homepage.nix`, `home-automation.nix`, `opencloud.nix`, and `restic-backup.nix`. Laptop-oriented modules remain in `modules/` because they may be reused by a future workstation. Targeted evals confirmed VPS Uptime Kuma routing, VPS Hetzner DDNS, crisuflix Homepage, and crisuflix OpenCloud. `nixos-rebuild dry-build --flake .#vps` and `nixos-rebuild dry-build --flake .#crisuflix` both succeed.

Crisuflix Homepage entries are now contributed by service modules through local aggregation options in `hosts/crisuflix/homepage.nix`: `local.homepageServices` and `local.homepageWidgets`. `hosts/crisuflix/home-automation.nix` contributes Home Assistant, ESPHome, and Music Assistant entries; `hosts/crisuflix/opencloud.nix` contributes OpenCloud; new `hosts/crisuflix/glances.nix` owns the Glances service/systemd override and contributes both the Glances widget and service entry. VPS/external/manual entries such as Gotify, Uptime Kuma, Headplane, Traefik, Dockge, UniFi, and CUPS remain in `homepage.nix` because their owning service modules are not imported by crisuflix. Homepage service/widget evals pass, and dry builds for both `crisuflix` and `vps` succeed.

Crisuflix was deployed with `sudo nixos-rebuild switch --flake .#crisuflix`. The first non-sudo switch built successfully but failed to set `/nix/var/nix/profiles/system` due to permissions; the sudo switch completed. Post-deploy checks: `homepage-dashboard.service`, `glances.service`, and `opencloud.service` are active; `http://127.0.0.1:3000` returns 200 for Homepage; Glances responds successfully to GET on `http://127.0.0.1:61208`.

Home-automation-related firewall openings moved from `hosts/crisuflix/default.nix` into `hosts/crisuflix/home-automation.nix`: Home Assistant, MQTT/Mosquitto, Music Assistant UI/stream ports, and the Yamaha MusicCast UDP iptables allow rule. Homepage's firewall port moved into `hosts/crisuflix/homepage.nix`. UPS/NUT config moved into new `hosts/crisuflix/ups.nix`, including the NUT firewall port. Targeted evals for merged firewall ports and UPS config pass. `nixos-rebuild dry-build --flake .#crisuflix` succeeded, followed by `sudo nixos-rebuild switch --flake .#crisuflix`. Post-switch checks: `homepage-dashboard.service` and `glances.service` are active, Homepage returns 200 on `http://127.0.0.1:3000`, Glances GET succeeds on `http://127.0.0.1:61208`, and NUT units `upsd.service`, `upsdrv.service`, and `upsmon.service` are active.

Headplane on VPS has been migrated in config from the nixpkgs `services.headplane` module to the upstream pinned `tale/headplane` NixOS module. `hosts/vps/headscale.nix` disables the nixpkgs Headplane module, imports `inputs.headplane.nixosModules.headplane`, uses upstream `headscale.api_key_path`, removes old agent preauth config, and declares `/var/lib/headplane/agent` as `headscale:headscale` via tmpfiles. Local

Docker on crisuflix now waits for Tailscale before starting. `hosts/crisuflix/default.nix` orders `docker.service` after/wants `tailscaled.service` and `tailscaled-set.service`, and adds a `preStart` gate that waits up to 120 seconds for `tailscale ip -4` to return `100.64.0.1`. This prevents Docker from auto-restoring `restart=unless-stopped` containers before local Traefik can bind `100.64.0.1:80/443` and before traefik-kop can use `tailscale0`. Local eval and `nixos-rebuild dry-build --flake .#crisuflix` succeeded. After reboot, `tailscaled.service` is active, `tailscaled-set.service` completed before Docker started, Docker is active, the `traefik` container is bound to `100.64.0.1:80/443`, `traefik-kop` publishes routes using `100.64.0.1`, and `https://ai.cri.su` returns 200.

VPS traefik-kop reboot fix has been simplified in config: `networkVars.hosts.vps` is now the stable tailnet IP `100.64.0.4` and `networkVars.hosts.crisuflix` is now `100.64.0.1`, removing MagicDNS from Redis bind/provider/firewall paths. `hosts/vps/reverse-proxy.nix` now orders Traefik after/wants `redis-traefik.service`. Local eval confirms Redis binds `100.64.0.4`, Traefik uses Redis endpoint `100.64.0.4:6379`, and Traefik wants/starts after `redis-traefik.service`; `nixos-rebuild dry-build --flake .#vps` succeeds. VPS was deployed and rebooted. Runtime recovered without manual restarts: `tailscaled`, `headscale`, `redis-traefik`, and `traefik` are active; Redis listens on `100.64.0.4:6379`; Traefik has Redis-backed routers; crisuflix can reach Redis; `https://ai.cri.su` returns 200; `https://traefik.cri.su` redirects to Authelia. Boot logs still show Redis initially failed with `bind: Cannot assign requested address` until Tailscale acquired `100.64.0.4`, so add a simple Redis `preStart` gate if clean boot logs/no temporary outage are desired.

NFS on crisuflix is tailnet-wide and firewall-scoped to `tailscale0`: `/mnt/veckjarvi/media`, `/mnt/veckjarvi/backups/haos-backup`, and `/mnt/illby/docker` are exported to `100.64.0.0/10`. Parent exports for media and docker use `crossmnt` so child ZFS datasets are visible. Laptop mounts media and docker via `crisuflix.tailnet.cri.su` using NFSv4.2; both crisuflix and laptop have been rebuilt and switched, and `/mnt/crisuflix-media` plus `/mnt/crisuflix-docker` are verified active on laptop.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

Shared core Nix settings now trust the personal Cachix cache `https://llego.cachix.org` with public key `llego.cachix.org-1:WzO82OCKQr+mNapPewBwEeN5Ui5vPjduTIYfrD0YFwQ=`. Laptop eval confirms the substituter and key are present. The built `album-downloader` and `bandsnatch` outputs were pushed to Cachix and their narinfo entries were verified, so matching laptop rebuilds should substitute them instead of compiling Rust locally.

Yazi now has a repo-managed `zfs.yazi` plugin under `modules/core/dots/yazi/plugins/zfs.yazi/main.lua`. `modules/basic-cli.nix` exposes it through hjem, `yazi.toml` registers it as a directory fetcher, and `init.lua` loads it. The plugin reads `/proc/self/mountinfo`, caches exact local ZFS mountpoints, and appends a cyan `ZFS` linemode badge only to directories that are dataset roots. Lua syntax validation passed, `nix eval .#nixosConfigurations.crisuflix.config.system.build.toplevel.drvPath` succeeds, and `sudo nixos-rebuild switch --flake .#crisuflix` completed. The activated plugin file exists at `~/.config/yazi/plugins/zfs.yazi/main.lua`, and manual Yazi testing confirmed the badge works.

## Architecture Principles

- Services that bind to or firewall tailnet endpoints should use stable tailnet IPs or explicit readiness gates instead of depending on MagicDNS during boot.
- Traefik providers backed by local services should have explicit systemd ordering and should prefer local loopback endpoints where possible.
- `networkVars.hosts.vps` and `networkVars.hosts.crisuflix` intentionally use stable tailnet IPs, not MagicDNS names, so boot-critical bind, firewall, and provider paths stay deterministic.
- Stable tailnet IPs remove MagicDNS races but do not prove the IP is assigned at boot; services binding those IPs still need a Tailscale readiness gate when temporary failure/retry is not acceptable.
- Multi-service Docker stacks published through traefik-kop should set both `traefik.http.routers.<router>.service` and `traefik.http.services.<service>.loadbalancer.server.port` explicitly, avoiding generated service-name churn and stale Redis provider state.
- VPS-local Traefik dynamic routes should live beside the service module that owns the backend. The VPS reverse proxy module should keep Traefik infrastructure, shared middlewares, and routes to services hosted elsewhere, such as crisuflix.
- Host-specific service and edge configs belong under `hosts/<host>/`; only modules expected to be reused by more than one host should remain under `modules/`.
- For Homepage, entries for services running on crisuflix should live beside the owning crisuflix service module and be merged through `local.homepageServices` / `local.homepageWidgets`; entries for external or VPS-owned services stay in `hosts/crisuflix/homepage.nix` unless a cross-host metadata layer is introduced.
- Firewall openings should live beside the service that owns the listener where practical; keep only host-general ports in `hosts/<host>/default.nix`.
- Shared binary caches belong in `modules/core/default.nix` when all hosts may consume the same privately built closures.
- Disko whole-disk targets should use `/dev/disk/by-id`; non-ZFS local filesystems should use UUID/PARTUUID-backed `fileSystems` entries; ZFS datasets should stay ZFS-native via pool imports with by-id vdev paths.
- Yazi extensions should be managed as repo-owned dotfiles through hjem when they are small/local customizations, instead of using `ya pkg` outside Nix control.

## Top 3 Next Actions

- Rebuild laptop with the committed Cachix settings and confirm `album-downloader`/`bandsnatch` substitute from `llego.cachix.org`.

## Blockers

- None.
