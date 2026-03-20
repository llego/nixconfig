# NixOS Configuration

Multi-host NixOS flake configuration managing 5 systems with modular architecture.

Dotfiles for `~/.config` are maintained separately at: https://github.com/llego/dotfiles

## Hosts

- **laptop** - Main development machine (Intel, Niri WM, desktop apps)
- **gamestation** - Gaming PC (AMD CPU, NVIDIA GPU, Steam)
- **christiansandberg** - Remote server at christiansandberg.fi (Docker, SSH hardening)
- **crisuflix** - Home NAS/media server (ZFS, Docker, NFS, UPS)
- **rpi5** - Raspberry Pi 5 (Home Assistant kiosk, RuuviCollector)

## Structure

```text
.
├── flake.nix                          # Main flake configuration
├── secrets.nix                        # Agenix secrets key configuration
├── hosts/                             # Per-host configurations
│   ├── laptop.nix
│   ├── gamestation.nix
│   ├── christiansandberg.nix          # + disk-config.nix
│   ├── crisuflix.nix                  # + disk-config.nix
│   └── rpi5.nix
├── modules/                           # Reusable NixOS modules
│   ├── core.nix                       # Base system (zsh, git, nix settings)
│   ├── basic-cli.nix                  # CLI tools (helix, yazi, lazygit)
│   ├── apps.nix                       # GUI apps (Zen Browser, Thunderbird)
│   ├── desktop-environment.nix        # Wayland/Niri + greetd
│   ├── printer.nix                    # CUPS + Avahi
│   ├── vpn.nix                        # Mullvad VPN
│   ├── wifi-networks.nix              # NetworkManager profiles
│   ├── downloaders.nix                # Media downloaders
│   ├── swayidle.nix                   # Idle management
│   ├── secrets.nix                    # Agenix integration
│   └── storj-backup.nix               # Storj cloud backup
├── pkgs/                              # Custom packages as flakes
│   ├── album-downloader/              # Bandcamp downloader wrapper
│   └── RuuviCollector/                # BLE sensor reader for RuuviTags
├── secrets/                           # Encrypted agenix secrets
│   ├── initial-password.age
│   ├── nut-password.age
│   └── beszel-env.age
└── z_lab/                             # Experimental/WIP features
```

## Secrets Management

This configuration uses [agenix](https://github.com/ryantm/agenix) for secrets:

```bash
# Edit a secret (decrypts, opens editor, re-encrypts)
agenix -e secrets/initial-password.age

# Re-key all secrets (after adding/removing SSH keys)
agenix -r
```

Secrets are encrypted to SSH host keys + user keys defined in `secrets.nix`.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed architecture, module composition patterns, and deployment procedures.

## crisuflix Networking

`crisuflix` uses dual physical NICs, each attached to a Linux bridge:

- **br0** (via `enp5s0`): primary LAN (`192.168.1.0/24`), host IPs `192.168.1.101` and `192.168.1.103`
- **br1** (via `enp6s0`): IoT LAN (`192.168.3.0/24`), host IP `192.168.3.103`

### Intended usage

- **br0** is the main management and internet-facing network for the host (default route via `192.168.1.1`)
- **br1** is used to discover and control IoT devices (Shelly plugs, IP camera, charger, etc.)
- Service discovery is enabled on both bridges (`avahi.allowInterfaces = [ "br0" "br1" ]`)

### Practical examples from current setup

- Printer access on IoT subnet (`192.168.3.125:631`)
- ESPHome/API traffic to IoT devices (`192.168.3.x`, e.g. `:6053`)
- Device control sessions from `crisuflix` to IoT endpoints (`:8080`, `:8008`, etc.)

This separation keeps IoT traffic reachable from `crisuflix` while preserving `br0` as the primary host/network egress path.
