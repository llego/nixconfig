# NixOS Configuration

Multi-host NixOS flake.

## Hosts

| Host                        | Purpose               |
| --------------------------- | --------------------- |
| `laptop`                    | Daily driver          |
| `vps` / `christiansandberg` | Public edge           |
| `crisuflix`                 | NAS and home services |
| `rpi5`                      | Home Assistant kiosk  |

## Layout

| Path         | Purpose                     |
| ------------ | --------------------------- |
| `hosts/`     | Per-machine NixOS configs   |
| `modules/`   | Reusable NixOS modules      |
| `dots/`      | User config sources         |
| `pkgs/`      | Local packages              |
| `secrets/`   | agenix secrets              |
| `docs/`      | Long-form notes             |
| `HANDOFF.md` | Current state, next actions |

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix) and are encrypted to SSH host keys plus user keys from `secrets.nix`.

```bash
agenix -e secrets/initial-password.age
agenix -r
```

## Custom Packages

Packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.
