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
