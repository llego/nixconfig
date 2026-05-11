# NixOS Configuration

Multi-host NixOS flake managing 4 systems. Dotfiles are managed with [hjem](https://github.com/feel-co/hjem) and symlinked back to this repo via [hjem-impure](https://github.com/Rexcrazy804/hjem-impure).

There are docker containers running on crisuflix. Docker compose stacks are in /mnt/illby/docker/stacks and app configs are in /mnt/illby/docker/data.

## Hosts

| Host | Purpose | Key Features |
|------|---------|--------------|
| **laptop** | Main development machine | Niri WM, Noctalia, Intel GPU, NFS mounts, Tailscale |
| **vps** (hostname: christiansandberg) | Remote server | Gotify, Uptime Kuma, fail2ban, Authelia, static website |
| **crisuflix** | Home NAS/media server | ZFS, Docker, Home Assistant, Music Assistant, ESPHome, NFS |
| **rpi5** | Home Assistant kiosk | Chromium kiosk, nightly reboot |

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
│   ├── core/              # Core system components
│   │   ├── dots/          # Dotfiles source (helix, yazi, niri, opencode, etc.)
│   │   ├── default.nix    # Main core module (git, nix, locale, SSH, users)
│   │   ├── basic-cli.nix  # CLI tools + configs: helix, yazi, oh-my-posh, zsh, htop
│   │   ├── hjem.nix       # Hjem infrastructure + beets config
│   │   ├── agenix.nix     # Secrets management integration
│   │   └── networking-variables.nix # Network configuration variables
│   ├── apps.nix           # Apps + configs: Zen, Thunderbird, LibreOffice, OpenCode
│   ├── desktop-environment.nix  # Desktop + configs: Niri, Noctalia, GTK, SSH shortcuts
│   ├── home-automation.nix # HA, Music Assistant, ESPHome, Mosquitto
│   ├── restic-backup.nix  # Restic cloud backup (Hetzner, legacy Storj)
│   ├── downloaders.nix    # yle-dl, svtplay-dl, album-downloader
│   ├── printer.nix        # CUPS, Avahi printing support
│   └── wifi-networks.nix  # NetworkManager wireless profiles
├── pkgs/                  # Custom packages
│   ├── album-downloader/  # Bandcamp downloader wrapper
│   └── RuuviCollector/    # BLE sensor reader for RuuviTags
└── secrets/               # agenix-encrypted secrets
```

## Build & Deployment

Always use crisuflix as the remote build host. Add `--build-host llego@crisuflix.home` to all commands except when running on crisuflix itself.

Run `hostname` before `nixos-rebuild`. Most often you are on crisuflix.

If you have created new files, add them to git before running `nixos-rebuild`:
```bash
git add .
```



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
- `laptop`: core, apps, desktop-environment, printer, wifi-networks, downloaders
- `vps`: core
- `crisuflix`: core, home-automation, restic-backup
- `rpi5`: core, wifi-networks

### Dotfiles (hjem)

Dotfiles are managed with [hjem](https://github.com/feel-co/hjem) using a distributed approach where configurations are co-located with their package definitions.

**Architecture:**
- **Source**: Configurations stored in `modules/core/dots/`
- **Management**: [hjem-impure](https://github.com/Rexcrazy804/hjem-impure) symlinks to `~/.config/`
- **Live Editing**: Changes to source files take effect without rebuilds
- **Distribution**: Each module manages its own application configs via hjem

**Organization:**
- **basic-cli.nix**: helix, yazi, oh-my-posh configs
- **desktop-environment.nix**: niri, kanshi, GTK, noctalia configs + SSH shortcuts  
- **apps.nix**: opencode configs
- **core/hjem.nix**: hjem infrastructure + beets config (docker dependency)

**Covered Applications:**
- **CLI Tools**: helix, yazi, oh-my-posh, beets
- **Desktop**: niri, kanshi, GTK bookmarks, noctalia (+ wallpapers)
- **Development**: opencode (settings, agents)
- **Shortcuts**: SSH application desktop files

**Benefits:**
- ✅ Live editing without rebuilds
- ✅ Standard user config locations (`~/.config/`)
- ✅ Package installations co-located with their configurations
- ✅ Consistent management across all tools

### crisuflix

- **Storage**: ZFS pools `illby` (apps) and `veckjarvi` (media), 8 SATA + 3 NVMe drives
- **Services**: Docker, home-automation module, NFS exports, sanoid snapshots
- **Network**: Dual bridges (br0: 192.168.1.101/103, br1: 192.168.3.103)
- **Monitoring**: Beszel agent with SMART, Cloudflare DDNS
- **UPS**: NUT (usbhid-ups driver)

### rpi5

- cage compositor with single Chromium window

### Infrastructure Architecture (VPS ↔ Crisuflix)

Both servers form a unified infrastructure connected via Tailscale VPN:

**Tailscale Connectivity**
- VPS (christiansandberg.fi): `100.78.37.16`
- Crisuflix (NAS): `100.123.67.48`
- All inter-server traffic routes through the secure Tailscale mesh

**Multi-Host Reverse Proxy (traefik-kop)**
- VPS runs Traefik (ports 80/443) + Redis (port 6379, Tailscale-only)
- Crisuflix Docker containers use traefik-kop agent to publish routes
- Flow: Container labels → Redis (via Tailscale) → Traefik → Public access

**Authelia (Centralized Auth)**
- Runs on VPS only; protects services on both servers
- Forward-auth middleware in Traefik intercepts all protected routes
- Traffic flow: User → VPS Traefik → Authelia check → Service (via Tailscale)

Expose crisuflix containers with labels:
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
- `hjem` - Dotfiles manager
- `hjem-impure` - Impure dotfiles support
- `christiansandberg-website` - Static website for VPS
- `album-downloader`, `ruuvi` - Local custom packages

## Custom Packages

Both packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.

**RuuviCollector**: Java/Maven BLE sensor reader. Full NixOS module with 20+ options, security.wrappers for BLE tools, InfluxDB output.

**Album Downloader**: Shell wrapper for bandcamp-collection-downloader + rsync.
