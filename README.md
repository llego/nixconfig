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

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix) and are encrypted to SSH host keys plus user keys from `secrets.nix`.

```bash
agenix -e secrets/initial-password.age
agenix -r
```

## Custom Packages

Packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.
