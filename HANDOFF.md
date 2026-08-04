# HANDOFF

Last updated: 2026-08-03 20:42 UTC

## Current State

Flake path args were centralized: `flake.nix` now defines `reporoot = ./.` and `dots = reporoot + "/dots"`, passes them through shared `commonSpecialArgs`, and modules use those args instead of relative `../dots` / `../../secrets` references. `dots` remains a path for file sources; `modules/core/hjem.nix` stringifies it only for `hjem-impure.dotsDir`, which requires a string-wrapped path. `nix eval` succeeded for `laptop`, `vps`, `crisuflix`, `rpi5`, and `laptop-installer` (`--impure` for installer due SSH key access). No secrets were added to tracked files.

Headplane on VPS has been migrated in config from the nixpkgs `services.headplane` module to the upstream pinned `tale/headplane` NixOS module. `hosts/vps/headscale.nix` disables the nixpkgs Headplane module, imports `inputs.headplane.nixosModules.headplane`, uses upstream `headscale.api_key_path`, removes old agent preauth config, and declares `/var/lib/headplane/agent` as `headscale:headscale` via tmpfiles. Local

Docker on crisuflix now waits for Tailscale before starting. `hosts/crisuflix/default.nix` orders `docker.service` after/wants `tailscaled.service` and `tailscaled-set.service`, and adds a `preStart` gate that waits up to 120 seconds for `tailscale ip -4` to return `100.64.0.1`. This prevents Docker from auto-restoring `restart=unless-stopped` containers before local Traefik can bind `100.64.0.1:80/443` and before traefik-kop can use `tailscale0`. Local eval and `nixos-rebuild dry-build --flake .#crisuflix` succeeded. After reboot, `tailscaled.service` is active, `tailscaled-set.service` completed before Docker started, Docker is active, the `traefik` container is bound to `100.64.0.1:80/443`, `traefik-kop` publishes routes using `100.64.0.1`, and `https://ai.cri.su` returns 200.

VPS traefik-kop reboot fix has been simplified in config: `networkVars.hosts.vps` is now the stable tailnet IP `100.64.0.4` and `networkVars.hosts.crisuflix` is now `100.64.0.1`, removing MagicDNS from Redis bind/provider/firewall paths. `hosts/vps/reverse-proxy.nix` now orders Traefik after/wants `redis-traefik.service`. Local eval confirms Redis binds `100.64.0.4`, Traefik uses Redis endpoint `100.64.0.4:6379`, and Traefik wants/starts after `redis-traefik.service`; `nixos-rebuild dry-build --flake .#vps` succeeds. VPS was deployed and rebooted. Runtime recovered without manual restarts: `tailscaled`, `headscale`, `redis-traefik`, and `traefik` are active; Redis listens on `100.64.0.4:6379`; Traefik has Redis-backed routers; crisuflix can reach Redis; `https://ai.cri.su` returns 200; `https://traefik.cri.su` redirects to Authelia. Boot logs still show Redis initially failed with `bind: Cannot assign requested address` until Tailscale acquired `100.64.0.4`, so add a simple Redis `preStart` gate if clean boot logs/no temporary outage are desired.

## Top 3 Next Actions

## Blockers

- None.
