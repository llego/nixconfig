# NixOS Configuration

Multi-host NixOS flake. Dotfiles are managed with [hjem](https://github.com/feel-co/hjem) and [hjem-impure](https://github.com/Rexcrazy804/hjem-impure). Do not use home-manager.

## Hosts

| Host                        | Purpose               |
| --------------------------- | --------------------- |
| `laptop`                    | Daily driver          |
| `vps` / `christiansandberg` | Public edge           |
| `crisuflix`                 | NAS and home services |
| `rpi5`                      | Home Assistant kiosk  |

## Layout

- `hosts/`: per-machine NixOS configs.
- `modules/`: reusable NixOS modules.
- `dots/`: user config sources.
- `pkgs/`: local packages.
- `secrets/`: agenix secrets.
- `docs/`: long-form notes.
- `HANDOFF.md`: current state and next actions.

## Build And Deploy

Run `hostname` before `nixos-rebuild`. Use `crisuflix` as the remote build host unless the command is already running on `crisuflix`. If new files were added, stage them before rebuilding so the flake can see them.

```bash
git add .
```

```bash
# VPS, when not already on crisuflix
nixos-rebuild switch --flake .#vps \
  --build-host llego@crisuflix \
  --target-host llego@christiansandberg.fi --sudo

# VPS, when already on crisuflix
# Omit --build-host to avoid self-SSH host key verification issues.
nixos-rebuild switch --flake .#vps \
  --target-host llego@christiansandberg.fi --sudo

# NAS, when not already on crisuflix
nixos-rebuild switch --flake .#crisuflix \
  --build-host llego@crisuflix

# NAS, when already on crisuflix
nixos-rebuild switch --flake .#crisuflix

# Raspberry Pi 5, use boot for remote safety
nixos-rebuild boot --flake .#rpi5 \
  --build-host llego@crisuflix \
  --target-host llego@rpi5 --sudo
```

## Architecture

- Keep durable architecture decisions here; keep current state in `HANDOFF.md`.
- Keep host-specific config in `hosts/` and reusable config in `modules/`.
- Keep service firewall openings and service-owned routing beside the service where practical.
- Boot-critical services that bind tailnet addresses need explicit ordering or readiness gates.
- Docker services exposed publicly should use explicit traefik-kop router/service labels.
- Shared binary caches belong in shared modules only when all hosts may consume them.
- Use stable disk identifiers: by-id for whole-disk targets, UUID/PARTUUID for local filesystems, and native ZFS imports for ZFS datasets.

Expose a `crisuflix` container publicly with labels like:

```yaml
labels:
  - "kop.namespace=vps"
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.cri.su`)"
```

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix) and are encrypted to SSH host keys plus user keys from `secrets.nix`.

```bash
agenix -e secrets/initial-password.age
agenix -r
```

## Custom Packages

Packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.
