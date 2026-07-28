# Global Rules

## General

- Don't assume on which machine you are running. Use hostname command.
- You can use `nix-shell -p ...` to run python and other packages not installed on the system

## System

- OS: NixOS. Never suggest apt, brew, pip, or other imperative package managers.
- Do not suggest or use home-manager.
- Root-owned files require `sudo tee` to write.
- Home directory (`~/`) is owned by `llego` — no sudo needed for files there.

## Infrastructure

4 NixOS hosts plus UniFi:

- **laptop**: daily driver
- **vps** (`christiansandberg.fi`) Traefik reverse proxy, Headscale, Authelia, public-facing services
- **crisuflix**: NAS, ZFS, Docker (configs in /mnt/illby/docker), Home Assistant (running as NixOS service), Music Assistant (running as NixOS service)
  - config directories for HA and MA are in /mnt/illby/appstorage/homeassistant /mnt/illby/appstorage/music-assistant, respectively
- **rpi5**: Chromium kiosk for Home Assistant
- **unifi.home** UniFi Dream Router. Can be ssh'd into from crisuflix by `ssh root@unifi.home`.

All inter-server communication over Tailscale. NixOS config at `~/nixconfig`.

## Docker

Crisuflix is the Docker host:

- Stacks: `/mnt/illby/docker/stacks`
- App data: `/mnt/illby/docker/data`

**Routing:** crisuflix containers publish routes to VPS via traefik-kop (Docker labels → Redis on VPS → Traefik). New public services on crisuflix need traefik-kop labels. Auth via Authelia forward-auth middleware on VPS.

## Home Assistant

- MCP server at `https://ha-mcp.llego.me/mcp` (requires `HA_MCP_TOKEN` env var)
