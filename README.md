# NixOS Configuration

Multi-host NixOS flake for four systems. Dotfiles are managed with [hjem](https://github.com/feel-co/hjem) and symlinked to standard user config paths with [hjem-impure](https://github.com/Rexcrazy804/hjem-impure). Do not use home-manager.

## Hosts

| Host                        | Purpose               | Main Roles                                                           |
| --------------------------- | --------------------- | -------------------------------------------------------------------- |
| `laptop`                    | Daily driver          | Niri, Noctalia, Intel GPU, NFS mounts, Headscale                     |
| `vps` / `christiansandberg` | Public edge           | Traefik, Authelia, Redis, Gotify, Uptime Kuma, fail2ban, static site |
| `crisuflix`                 | NAS and home services | ZFS, Docker, Home Assistant, Music Assistant, ESPHome, NFS, restic   |
| `rpi5`                      | Home Assistant kiosk  | Cage, Chromium kiosk                                                 |

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

- Host modules are composed narrowly: `laptop` imports core, apps, desktop-environment, printer, wifi-networks, downloaders; `vps` imports core; `crisuflix` imports core, home-automation, restic-backup; `rpi5` imports core and wifi-networks.
- Dotfile sources live in `modules/core/dots/` and are symlinked to `~/.config/`; edit the source directly and no rebuild is needed. The exception is oh-my-posh, which uses `environment.etc` because VPS does not have the live repo path required by hjem-impure symlinks.
- Docker compose stacks for `crisuflix` live in `/mnt/illby/docker/stacks`; app data lives in `/mnt/illby/docker/data`; shared app storage lives in `/mnt/illby/appstorage`.
- Session handoff and durable decisions are tracked in `HANDOFF.md`.

## Routing And Network

- Docker containers on `crisuflix` self-register through traefik-kop labels, then flow through Redis on `vps` to public Traefik routing.
- Native NixOS services such as Home Assistant, Glances, OpenCloud, Collabora, and Homepage use static Traefik routes in `hosts/vps/networking.nix`.
- Authelia on `vps` (`auth.cri.su`) protects both hosts with forward-auth middleware.
- Headscale split DNS routes `llego.me.` to VPS `dnsmasq` on `100.64.0.4`; `dnsmasq` answers `*.llego.me` with `crisuflix` at `100.64.0.1` for tailnet clients.
- `crisuflix` bridge `br0` is trusted LAN at `192.168.1.101/24`, gateway `192.168.1.1`; bridge `br1` is IoT at `192.168.3.103/24`.
- UniFi keeps `192.168.3.0/24` in custom zone `CUSTOM1`, blocking IoT to trusted LAN and allowing IoT to WAN. mDNS proxy is enabled on both networks as fallback.
- Avahi reflector on `crisuflix` bridges mDNS between `br0` and `br1`; IoT devices reach HA, MQTT, and ESPHome via `192.168.3.103` on the same subnet.

Expose a `crisuflix` container publicly with labels like:

```yaml
labels:
  - "kop.namespace=vps"
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.christiansandberg.fi`)"
```

## crisuflix Notes

- Storage: ZFS pools `illby` for apps and `veckjarvi` for media, backed by 8 SATA and 3 NVMe drives.
- Services: Docker, home-automation module, NFS exports, sanoid snapshots, Home Assistant, Music Assistant, ESPHome.
- Monitoring: Beszel agent with SMART.
- UPS: NUT with `usbhid-ups` driver.
- InfluxDB integration: config entry `path` must be `""`; `/` caused 404 during setup.

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix) and are encrypted to SSH host keys plus user keys from `secrets.nix`.

```bash
agenix -e secrets/initial-password.age
agenix -r
```

## Custom Packages

Packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.

- `RuuviCollector`: Java/Maven BLE sensor reader with a NixOS module, BLE security wrappers, and InfluxDB output.
- `Album Downloader`: shell wrapper for `bandcamp-collection-downloader` plus `rsync`.
