# NixOS Configuration

Multi-host NixOS flake managing 4 systems. Dotfiles for `~/.config` are maintained separately at https://github.com/llego/dotfiles.

## Hosts

| Host | Purpose | Key Features |
|------|---------|--------------|
| **laptop** | Main development machine | Niri WM, Intel GPU, NFS mounts, Tailscale |
| **vps** (hostname: christiansandberg) | Remote server | Docker, Traefik, Redis, Gotify, Uptime Kuma, fail2ban |
| **crisuflix** | Home NAS/media server | ZFS, Docker, Home Assistant, Music Assistant, ESPHome, NFS |
| **rpi5** | Home Assistant kiosk | Chromium kiosk, RuuviCollector BLE sensors, nightly reboot |

## Structure

```
├── flake.nix              # Main flake (nixosConfigurations only)
├── flake.lock             # Lock file
├── hosts/                 # Per-host configurations
│   ├── laptop/
│   ├── vps/               # christiansandberg.fi server
│   ├── crisuflix/
│   └── rpi5/
├── modules/               # Reusable NixOS modules
│   ├── core.nix           # zsh, git, nix settings, locale, SSH
│   ├── basic-cli.nix      # helix, yazi, lazygit, bat, lsd
│   ├── apps.nix           # Zen Browser, Thunderbird, LibreOffice
│   ├── desktop-environment.nix  # Niri, greetd/tuigreet
│   ├── ai.nix             # AI development tools
│   ├── printer.nix        # CUPS, Avahi
│   ├── vpn.nix            # Mullvad VPN
│   ├── wifi-networks.nix  # NetworkManager profiles
│   ├── downloaders.nix    # yle-dl, svtplay-dl, album-downloader
│   ├── swayidle.nix       # Idle management
│   ├── authelia.nix       # Authelia authentication
│   ├── agenix.nix         # Secrets integration
│   ├── home-automation.nix # HA, Music Assistant, ESPHome, Mosquitto, Avahi
│   └── storj-backup.nix   # Storj cloud backup
├── pkgs/                  # Custom packages
│   ├── album-downloader/  # Bandcamp downloader wrapper
│   └── RuuviCollector/    # BLE sensor reader for RuuviTags
├── secrets/               # agenix-encrypted secrets
└── iso/                   # ISO configuration
```

## Build & Deployment

To AI agents:

Always use crisuflix as the remote build host. Add `--build-host llego@crisuflix.home` to all commands except when running on crisuflix itself.

Run `hostname` before `nixos-rebuild`. Most often you are on crisuflix.



```bash
# VPS (christiansandberg.fi)
nixos-rebuild switch --flake .#vps \
  --build-host llego@crisuflix.home \
  --target-host "llego@christiansandberg.fi" --sudo

# NAS (crisuflix.home)
nixos-rebuild switch --flake .#crisuflix \
  --build-host llego@crisuflix.home \
  --target-host "llego@crisuflix.home" --sudo

# Raspberry Pi 5 (use boot for remote safety)
nixos-rebuild boot --flake .#rpi5 \
  --build-host llego@crisuflix.home \
  --target-host llego@rpi5.home --sudo
```

## Secrets Management

Uses [agenix](https://github.com/ryantm/agenix). Secrets are encrypted to SSH host keys + user keys defined in `secrets.nix`.

```bash
agenix -e secrets/initial-password.age    # Edit a secret
agenix -r                                  # Re-key all secrets
```

## Key Patterns

### Modular Composition

Each host imports only the modules it needs:
- `laptop`: core, basic-cli, ai, apps, desktop-environment, printer, wifi-networks, vpn, downloaders
- `vps`: core, basic-cli, authelia
- `crisuflix`: core, basic-cli, home-automation, ai
- `rpi5`: core, basic-cli, wifi-networks, ruuvi module

### NAS Server (crisuflix)

- **Storage**: ZFS pools `illby` (apps) and `veckjarvi` (media), 8 SATA + 3 NVMe drives
- **Services**: Docker, home-automation module, NFS exports, sanoid snapshots
- **Network**: Dual bridges (br0: 192.168.1.101/103, br1: 192.168.3.103)
- **Monitoring**: Beszel agent with SMART, Cloudflare DDNS
- **UPS**: NUT (usbhid-ups driver)

### Kiosk Mode (rpi5)

- cage compositor with single Chromium window

### Traefik Reverse Proxy (traefik-kop)

Multi-host setup: vps runs Traefik + Redis; crisuflix runs Docker containers with traefik-kop agent. Communication over Tailscale. Expose containers with labels:

```yaml
labels:
  - "kop.namespace=vps"
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.christiansandberg.fi`)"
```

## Flake Inputs

- `nixpkgs` - Unstable channel
- `raspberry-pi-nix` - RPi5 hardware support
- `noctalia` - Wayland shell
- `zen-browser` - Browser package
- `disko` - Declarative disk partitioning
- `agenix` - Secrets management
- `album-downloader`, `ruuvi` - Local custom packages

## Custom Packages

Both packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.

**RuuviCollector**: Java/Maven BLE sensor reader. Full NixOS module with 20+ options, security.wrappers for BLE tools, InfluxDB output.

**Album Downloader**: Shell wrapper for bandcamp-collection-downloader + rsync.
