# Global Rules

## System
- OS: NixOS. Never suggest apt, brew, pip, or other imperative package managers.
- NixOS configuration is at `~/nixconfig`.
- Dotfiles are at `~/nixconfig/modules/home/`, managed with hjem.
- Do not suggest or use home-manager.
- Always check the current hostname before running `nixos-rebuild` to ensure the correct host configuration is targeted.
- Root-owned files require `sudo tee` to write.
- Home directory (`~/`) is owned by `llego` — no sudo needed for files there.

## Docker (crisuflix)
- Docker compose stacks: `llego@crisuflix:/mnt/illby/docker/stacks`
- Docker app data/configs: `llego@crisuflix:/mnt/illby/docker/data`
- Some apps have config at: `llego@crisuflix.home:/mnt/illby/appstorage`

## Home Assistant
- A Home Assistant MCP server is connected via `ha-mcp` at `https://ha-mcp.llego.me/mcp`.
- Use it to query and control the Home Assistant instance at `http://192.168.1.101:8123`.
- Home Assistant configuration files are at `/mnt/illby/docker/data/homeassistant/ha-config`.

## christiansandberg Server

Remote NixOS server at christiansandberg.fi with Docker services:
- SSH: `ssh llego@christiansandberg.fi`
- Docker stacks: `/opt/stacks`
- Docker app data: `/opt/appdata`
