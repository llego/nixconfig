# HANDOFF

Last updated: 2026-07-15 19:08 UTC

## Current State

Headplane on VPS has been migrated in config from the nixpkgs `services.headplane` module to the upstream pinned `tale/headplane` NixOS module. `hosts/vps/headscale.nix` disables the nixpkgs Headplane module, imports `inputs.headplane.nixosModules.headplane`, uses upstream `headscale.api_key_path`, removes old agent preauth config, and declares `/var/lib/headplane/agent` as `headscale:headscale` via tmpfiles. Local

Headplane Browser SSH follow-up: Crisuflix advertises Tailscale SSH with `--ssh` and local status shows `https://tailscale.com/cap/ssh`. `hosts/vps/reverse-proxy.nix` now attaches a `headscale-cors` Traefik headers middleware to the `headscale.cri.su` router so Browser SSH on `headplane.cri.su` can reach Headscale cross-origin. The Browser SSH button appears, but the deployed Headplane package currently shows `Browser SSH is not available` because the Nix build does not serve `/admin/hp_ssh.wasm` and `/admin/wasm_exec.js`. Upstream PR `tale/headplane#588` fixes the package by copying the WASM assets into `public/` and running `pnpm build`; it has passed checks, so the current decision is to wait for merge and then update the `headplane` flake input rather than carrying a local overlay. Local eval and `nixos-rebuild dry-build --flake .#vps` succeed for the current config.

Headscale now has a generated HuJSON policy in `hosts/vps/headscale.nix`: broad `acls` preserve the existing all-to-all tailnet behavior, and an `ssh` rule allows `autogroup:member` to `autogroup:self` as local user `llego` for Tailscale/Headplane Browser SSH. Local eval, generated policy inspection, and `nixos-rebuild dry-build --flake .#vps` succeed; VPS deploy is pending.

Docker on crisuflix now waits for Tailscale before starting. `hosts/crisuflix/default.nix` orders `docker.service` after/wants `tailscaled.service` and `tailscaled-set.service`, and adds a `preStart` gate that waits up to 120 seconds for `tailscale ip -4` to return `100.64.0.1`. This prevents Docker from auto-restoring `restart=unless-stopped` containers before local Traefik can bind `100.64.0.1:80/443` and before traefik-kop can use `tailscale0`. Local eval and `nixos-rebuild dry-build --flake .#crisuflix` succeed; deploy/reboot verification is pending.

NFS on crisuflix is tailnet-wide and firewall-scoped to `tailscale0`: `/mnt/veckjarvi/media`, `/mnt/veckjarvi/backups/haos-backup`, and `/mnt/illby/docker` are exported to `100.64.0.0/10`. Parent exports for media and docker use `crossmnt` so child ZFS datasets are visible. Laptop mounts media and docker via `crisuflix.tailnet.cri.su` using NFSv4.2; both crisuflix and laptop have been rebuilt and switched, and `/mnt/crisuflix-media` plus `/mnt/crisuflix-docker` are verified active on laptop.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

## Architecture Principles

- Services that bind to Tailnet IPs or publish over `tailscale0` must not rely on generic `network-online.target`; they need an explicit Tailscale readiness gate or service-level retry.

## Top 3 Next Actions

- Wait for `tale/headplane#588` to merge, then run `nix flake lock --update-input headplane` and verify Browser SSH assets.
- Deploy crisuflix with `nixos-rebuild switch --flake .#crisuflix`, then reboot and verify Docker starts after `tailscale ip -4` reports `100.64.0.1`.
- After reboot, verify `traefik` binds `100.64.0.1:80/443` and `traefik-kop` publishes routes to VPS Redis for `llego.me` services.

## Blockers

Headplane Browser SSH is blocked on the upstream Nix package fix in `tale/headplane#588` unless a temporary local overlay is added.
