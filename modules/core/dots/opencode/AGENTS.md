# Global Rules

## System
- OS: NixOS. Never suggest apt, brew, pip, or other imperative package managers.
- NixOS configuration is at `~/nixconfig`.
- Dotfiles are at `~/nixconfig/modules/home/`, managed with hjem.
- Do not suggest or use home-manager.
- Always check the current hostname before running `nixos-rebuild` to ensure the correct host configuration is targeted.
- Root-owned files require `sudo tee` to write.
- Home directory (`~/`) is owned by `llego` — no sudo needed for files there.

## crisuflix
- Docker compose stacks: `llego@crisuflix:/mnt/illby/docker/stacks`
- Docker app data/configs: `llego@crisuflix:/mnt/illby/docker/data`
- Some apps have config at: `llego@crisuflix.home:/mnt/illby/appstorage`

## Home Assistant
- A Home Assistant MCP server is connected via `ha-mcp` at `https://ha-mcp.llego.me/mcp`.
- Use it to query and control the Home Assistant instance at `http://192.168.1.101:8123`.
- Home Assistant configuration files are at `/mnt/illby/docker/data/homeassistant/ha-config`.

## vps

Remote NixOS server at christiansandberg.fi:
- SSH: `ssh llego@christiansandberg.fi`

## Infrastructure Linking (VPS ↔ Crisuflix)

Both servers are linked via Tailscale VPN and share a unified reverse proxy architecture:

### Tailscale Connectivity
- **VPS (christiansandberg.fi):** `100.78.37.16`
- **Crisuflix (NAS):** `100.123.67.48`
- All inter-server communication happens over Tailscale's secure mesh network

### Traefik-kop Multi-Host Architecture
- **VPS runs:** Traefik reverse proxy (ports 80/443) + Redis server (port 6379)
- **Crisuflix runs:** Docker containers with traefik-kop agent
- How it works: Docker containers on crisuflix publish their routes via labels to Redis on VPS; Traefik on VPS reads from Redis and routes traffic accordingly
- Services on crisuflix are accessible via public domains routed through VPS
- Redis on VPS only accepts connections from crisuflix's Tailscale IP

### Authelia (Centralized Authentication)
- **Runs on:** VPS only
- **Protects:** Services on both VPS and crisuflix
- **Method:** Forward-auth middleware in Traefik
- Traffic flow: User → VPS Traefik → Authelia check → Service on crisuflix (via Tailscale)

### Key Implications
- When adding new Docker services on crisuflix that need public access: use traefik-kop labels to publish to VPS
- When configuring auth: services on both servers use VPS Authelia
- When troubleshooting routing: check Tailscale connectivity first, then Redis connectivity
