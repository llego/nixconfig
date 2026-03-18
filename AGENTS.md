# AGENTS.md

This file provides guidance to OpenCode when working with code in this repository.

## Repository Overview

This is a multi-host NixOS flake configuration managing 6 different systems with a modular architecture. Dotfiles for ~/.config are maintained separately at https://github.com/llego/dotfiles.

## Build & Deployment Commands

### Build host
Always use crisuflix as the remote build host for all NixOS configurations. It has
more CPU/RAM than the laptop and supports aarch64 builds (needed for rpi5). Add
`--build-host llego@crisuflix.home` to every nixos-rebuild and nix build command.

### Local builds
```bash
# Laptop (main development machine)
# IMPORTANT: Always use sudo for local rebuilds
sudo nixos-rebuild switch --flake .#laptop \
  --build-host llego@crisuflix.home

# Gamestation (gaming PC)
sudo nixos-rebuild switch --flake .#gamestation \
  --build-host llego@crisuflix.home
```

### Remote deployments
```bash
# christiansandberg.fi server
nixos-rebuild switch --flake .#christiansandberg-bitti \
  --build-host llego@crisuflix.home \
  --target-host "llego@christiansandberg.fi" --sudo

# crisuflix NAS (TrueNAS replacement)
nixos-rebuild switch --flake .#crisuflix \
  --build-host llego@crisuflix.home \
  --target-host "llego@crisuflix.home" --sudo

# Raspberry Pi 5
nixos-rebuild boot --flake .#rpi5 \
  --build-host llego@crisuflix.home \
  --target-host llego@rpi5.home \
  --sudo
```

### Building SD card images
```bash
# RPi5 SD card image (requires aarch64 support)
nix build '.#nixosConfigurations.rpi5.config.system.build.sdImage' \
  --system aarch64-linux \
  --build-host llego@crisuflix.home

# Flash to SD card
zstd -dc result/linux.img.zst | sudo dd of=/dev/sdX bs=4M status=progress oflag=sync
```

## Architecture

### Host Configuration Strategy

Each host in `/hosts/` selectively imports modules based on purpose:

- **laptop** - Main development machine with Niri WM, apps, desktop environment, VPN, printer
- **christiansandberg-bitti** - Remote server at christiansandberg.fi with Docker, SSH hardening, disko disk config
- **crisuflix** - Home NAS/media server with ZFS storage, Docker services, monitoring
- **gamestation** - Gaming PC with NVIDIA GPU, Steam, uses home-manager for user configs
- **rpi5** - Raspberry Pi 5 running Home Assistant Chromium kiosk + RuuviCollector BLE sensor reader

### Module Composition Pattern

Modules in `/modules/` are reusable components imported selectively per host:

- **core.nix** - Foundation layer (zsh, git, sudo, nix settings, nh helper, locale, SSH)
- **basic-cli.nix** - CLI tooling (helix, yazi, lazygit, bat, lsd, etc.)
- **apps.nix** - Graphical applications (Zen Browser, Thunderbird, LibreOffice)
- **desktop-environment.nix** - Wayland/Niri setup with greetd/tuigreet, Noctalia shell
- **printer.nix** - CUPS with Avahi discovery
- **vpn.nix** - Mullvad VPN with systemd-resolved
- **wifi-networks.nix** - NetworkManager profiles
- **downloaders.nix** - Media downloaders (yle-dl, svtplay-dl, album-downloader)
- **swayidle.nix** - Idle management

Not all hosts import all modules - each host configuration imports only what it needs.

### Custom Package Integration

Two in-tree package flakes in `/pkgs/`:

**RuuviCollector** (`/pkgs/RuuviCollector/`)
- Java/Maven-based BLE sensor reader for RuuviTag environmental sensors
- Full NixOS module with 20+ configuration options
- Manages BLE scanning capabilities (lescan, hcitool, hcidump) via security.wrappers
- Stores sensor data to InfluxDB
- Used on rpi5 for environmental monitoring

**Album Downloader** (`/pkgs/album-downloader/`)
- Shell script wrapper using bandcamp-collection-downloader + rsync
- Simple flake with package output
- Used in downloaders.nix module

Both are referenced as flake inputs with `inputs.nixpkgs.follows = "nixpkgs"` to avoid duplication.

### Hardware Specialization

Each host has inline hardware configuration (no shared hardware-configuration.nix):

- **laptop** - Intel CPU/GPU, NFS mounts to crisuflix, Tailscale
- **gamestation** - NVIDIA GPU (open driver), AMD CPU, gaming stack
- **rpi5** - Uses raspberry-pi-nix flake, BLE support, cage kiosk compositor, nightly reboot timer
- **christiansandberg** - Static IPv6 (2a01:4f9:c010:803e::1), firewall ports 80/443, Tailscale
- **crisuflix** - Intel CPU (Xeon), 8 SATA + 3 NVMe drives, ZFS pools, dual network bridges (br0/br1), UPS-backed

### Experimental Code

`/z_lab/` contains work-in-progress features not yet integrated into active hosts:
- Alternative WM configs (Niri, Waybar)
- Stylix theming experiments
- AI development tools
- Yubikey support
- agenix secrets management structure

The underscore prefix sorts this directory to the end. Do not assume z_lab modules are in use unless explicitly imported by a host.

## Flake Structure

### Inputs
- `nixpkgs` - Follows unstable (not pinned to 25.11)
- `raspberry-pi-nix` - Hardware support for RPi5
- `noctalia` - Custom Wayland shell/desktop environment
- `zen-browser` - Custom browser package
- `disko` - Declarative disk partitioning (christiansandberg host)
- `album-downloader`, `ruuvi` - Local path/git inputs for custom packages

### Outputs
The flake only defines `nixosConfigurations` - no package, app, or overlay outputs.

### Nix Settings
- Experimental features: nix-command, flakes
- Binary cache: nix-community.cachix.org
- Auto-optimise-store enabled
- Substituters and trusted keys configured in core.nix (no flake-level nixConfig needed)

## Key Patterns

### Remote Server Hardening
christiansandberg.nix includes:
- SSH: no root login, no password auth, no keyboard-interactive
- fail2ban with 5 retries, 1h ban time
- Firewall: only ports 80, 443 open
- Disko for declarative disk layout

### BLE Capabilities Management
RuuviCollector on rpi5 requires specific capabilities for BLE scanning:
- hcitool needs cap_net_raw, cap_net_admin
- hcidump needs cap_net_raw, cap_net_admin
- Managed via security.wrappers in the RuuviCollector NixOS module

### Kiosk Mode
rpi5 runs a locked-down Home Assistant kiosk:
- cage compositor (single-app Wayland)
- Chromium in kiosk mode
- Nightly auto-reboot via systemd timer
- No desktop environment

### NFS Mounting
laptop has NFS mounts to crisuflix with auto-unmount on idle (600s timeout).

### crisuflix NAS Server

Home NAS/media server that replaced TrueNAS SCALE. Accessed via `llego@crisuflix.home`. Deploy from laptop: `nixos-rebuild switch --flake .#crisuflix --target-host "llego@crisuflix.home" --build-host llego@crisuflix.home --sudo`

**Storage:**
- Two ZFS pools: `illby` (apps/docker) and `veckjarvi` (media/backups)
- Sanoid manages automated snapshots (15min/hourly/daily/weekly/monthly)
- Monthly scrubs, weekly TRIM
- 11 drives total (8 SATA + 3 NVMe) with SMART monitoring

**Services:**
- Docker with containerized apps (Home Assistant, Jellyfin, Music Assistant, Frigate, Traefik)
- NFS exports to home network (192.168.1.0/24) and specific hosts
- Beszel monitoring agent (native NixOS service, not Docker)
- UPS monitoring (NUT) with graceful shutdown at 20% battery
- Tailscale for remote access

**Network:**
- Dual bridges: br0 (192.168.1.101, 192.168.1.103) and br1 (192.168.3.103)
- SSH hardening + fail2ban
- Firewall ports: SSH(22), NFS(111,2049,20048), UPS(3493), Media services(8095,8096,8098,8123), Beszel(45876), mDNS(5353)

**Key paths:**
- Docker: `/mnt/illby/docker/stacks/` (compose files), `/mnt/illby/docker/data/` (volumes)

## Configuration Philosophy

1. **Modular composition** - Hosts import only the modules they need
2. **No system-wide home-manager** - Only gamestation uses home-manager for user configs
3. **Self-contained packages** - Custom packages are full flakes with NixOS modules
5. **Hardware inline** - Each host defines its own hardware config directly
6. **Experimental isolation** - z_lab keeps WIP features separate from production hosts

## Making Changes

### Adding a new module
1. Create module file in `/modules/`
2. Import it in relevant host configuration(s) in `/hosts/`
3. Do not assume all hosts will use it

### Adding a new host
1. Create host file in `/hosts/`
2. Add nixosConfiguration entry in flake.nix outputs
3. Set appropriate specialArgs (inputs, username, hostname)
4. Import only the modules needed for that host's purpose

### Modifying custom packages
- RuuviCollector: Maven-based, uses fixed-output derivations for deps
- Album downloader: Simple shell script, edit wrapper directly
- Both have their own flake.nix - update there, not in main flake

### Testing changes
- Local: Use `nixos-rebuild test` for non-persistent testing
- Remote: Use `nixos-rebuild boot` to apply on next reboot (safer for remote systems)
- Always use `--flake .#hostname` to specify which host configuration to build
