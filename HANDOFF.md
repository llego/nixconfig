# HANDOFF

Last updated: 2026-07-09 10:20 UTC

## Current State

Headscale OIDC + Headplane deployed on VPS. All four hosts running.

Headplane on VPS has been migrated in config from the nixpkgs `services.headplane` module to the upstream pinned `tale/headplane` NixOS module. `hosts/vps/headscale.nix` disables the nixpkgs Headplane module, imports `inputs.headplane.nixosModules.headplane`, uses upstream `headscale.api_key_path`, removes old agent preauth config, and declares `/var/lib/headplane/agent` as `headscale:headscale` via tmpfiles. Local

Headplane Browser SSH follow-up: Crisuflix advertises Tailscale SSH with `--ssh` and local status shows `https://tailscale.com/cap/ssh`. `hosts/vps/reverse-proxy.nix` now attaches a `headscale-cors` Traefik headers middleware to the `headscale.cri.su` router so Browser SSH on `headplane.cri.su` can reach Headscale cross-origin. The Browser SSH button appears, but the deployed Headplane package currently shows `Browser SSH is not available` because the Nix build does not serve `/admin/hp_ssh.wasm` and `/admin/wasm_exec.js`. Upstream PR `tale/headplane#588` fixes the package by copying the WASM assets into `public/` and running `pnpm build`; it has passed checks, so the current decision is to wait for merge and then update the `headplane` flake input rather than carrying a local overlay. Local eval and `nixos-rebuild dry-build --flake .#vps` succeed for the current config.

Headscale now has a generated HuJSON policy in `hosts/vps/headscale.nix`: broad `acls` preserve the existing all-to-all tailnet behavior, and an `ssh` rule allows `autogroup:member` to `autogroup:self` as local user `llego` for Tailscale/Headplane Browser SSH. Local eval, generated policy inspection, and `nixos-rebuild dry-build --flake .#vps` succeed; VPS deploy is pending.

NFS on crisuflix is tailnet-wide and firewall-scoped to `tailscale0`: `/mnt/veckjarvi/media`, `/mnt/veckjarvi/backups/haos-backup`, and `/mnt/illby/docker` are exported to `100.64.0.0/10`. Parent exports for media and docker use `crossmnt` so child ZFS datasets are visible. Laptop mounts media and docker via `crisuflix.tailnet.cri.su` using NFSv4.2; both crisuflix and laptop have been rebuilt and switched, and `/mnt/crisuflix-media` plus `/mnt/crisuflix-docker` are verified active on laptop.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

## Architecture Principles

## Top 3 Next Actions

- Wait for `tale/headplane#588` to merge, then run `nix flake lock --update-input headplane`.
- Verify Headplane Browser SSH assets with `curl -I https://headplane.cri.su/admin/hp_ssh.wasm` and `curl -I https://headplane.cri.su/admin/wasm_exec.js`, then test Browser SSH to Crisuflix as `llego`.

## Blockers

Headplane Browser SSH is blocked on the upstream Nix package fix in `tale/headplane#588` unless a temporary local overlay is added.
