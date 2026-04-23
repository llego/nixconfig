# Global Rules

## System
- OS: NixOS. Never suggest apt, brew, pip, or other imperative package managers.
- Do not suggest or use home-manager.
- Root-owned files require `sudo tee` to write.
- Home directory (`~/`) is owned by `llego` — no sudo needed for files there.

## Infrastructure

4 hosts:
- **laptop**: daily driver (Niri WM, Intel GPU)
- **vps** (`christiansandberg.fi`, `100.78.37.16`): Traefik reverse proxy, Redis, Authelia, public-facing services
- **crisuflix** (`100.123.67.48`): NAS, ZFS, Docker, Home Assistant
- **rpi5**: Chromium kiosk

All inter-server communication over Tailscale. NixOS config at `~/nixconfig`.

## Docker

Services split across VPS and crisuflix. Crisuflix is the primary Docker host:
- Stacks: `/mnt/illby/docker/stacks`
- App data: `/mnt/illby/docker/data`
- App storage: `/mnt/illby/appstorage`

**Routing:** crisuflix containers publish routes to VPS via traefik-kop (Docker labels → Redis on VPS → Traefik). New public services on crisuflix need traefik-kop labels. Auth via Authelia forward-auth middleware on VPS.

## Home Assistant
- MCP server at `https://ha-mcp.llego.me/mcp` (requires `HA_MCP_TOKEN` env var)
- Web UI at `http://192.168.1.101:8123`
- Config files at `llego@crisuflix:/mnt/illby/docker/data/homeassistant/ha-config`
