# HANDOFF

Last updated: 2026-06-25 19:05 UTC

## Current State

Headscale OIDC + Headplane deployed on VPS. All four hosts running. Crisuflix, laptop, VPS, and rpi5 Tailscale are now declarative with agenix Headscale preauth keys. Crisuflix registers as node `13` / `100.64.0.1` and advertises approved routes for `192.168.1.0/24` and `192.168.3.0/24`; laptop registers as node `14` / `100.64.0.3` and accepts routes; VPS registers as node `15` / `100.64.0.4` and accepts routes; rpi5 registers as node `16` / `100.64.0.5` and accepts routes. Headscale split DNS routes `llego.me.` to a VPS `dnsmasq` responder on `100.64.0.4`, which answers `*.llego.me` as crisuflix `100.64.0.1` for tailnet clients. Key services: OpenCloud 7.0.0 + Collabora (OIDC via Authelia), Homepage dashboard (NixOS service), restic backups (Hetzner), traefik-kop routing, Headscale OIDC via Authelia, Headplane Web UI. Traefik dashboard exposed at `https://traefik.cri.su` with Authelia protection.

DNS-01 ACME and DDNS fully migrated away from Cloudflare/EuroDNS to Hetzner across both traefik instances.

IoT network isolation completed: UniFi `192.168.3.0/24` moved to custom zone (CUSTOM1), avahi reflector enabled on crisuflix for cross-subnet mDNS. `192.168.1.103` alias removed from br0 — Shelly devices migrated to `192.168.3.103`.

README consolidated to remove duplicated architecture, dotfile, routing, and network guidance while preserving deployment commands and operational notes.

Podman migration analysis drafted in `docs/podman-migration-analysis.md`. Current direction: migrate only currently running Docker stacks, prefer rootless Podman under `apps` for ordinary app containers, use `/mnt/illby/podman` for migrated Dockge/stacks config, and keep hardware/network-admin/socket/rootful exceptions explicit rather than forcing everything into one rootless socket scope.

YLE-to-Sonarr importer is a standalone crisuflix NixOS service/timer: `yle-sonarr-import.service` / `.timer`. It reads `/var/lib/yle-sonarr-import/series.yaml`, derives per-series state and download paths from each top-level Sonarr `titleSlug`, triggers Sonarr imports through `/downloads/yle-dl/<series-key>`, stores state/mapping/pending suggestions under `/var/lib/yle-sonarr-import/<series-key>`, sends Gotify notifications, and uses OpenRouter only to write pending mapping suggestions for review. Encrypted secret: `secrets/yle-sonarr-import-env.age`.

YLE importer AI suggestions now validate model output before writing pending review entries: no-match responses drop null `season`/`episode` fields, match responses must contain integer season/episode values, and suggested episodes must exist in the provided Sonarr candidates.

After clearing the existing `Tuuri: Tanssikohtaus` pending suggestion, the latest importer regenerated it without null season/episode fields. `OPENROUTER_API_KEY` was copied from `secrets/hermes-env.age` into `secrets/yle-sonarr-import-env.age`; crisuflix was rebuilt/switched, and the regenerated suggestion maps `Tuuri: Tanssikohtaus` to `S02E01 Dance Mode` with confidence `0.92`.

YLE importer state files were converted from JSON to YAML for easier manual review/editing. Each series uses `mapping.yaml`, `state.yaml`, and `pending-suggestions.yaml`, with one-time migration from existing `.json` files. Crisuflix was rebuilt/switched and `yle-sonarr-import.service` was run after the change.

YAML state files are group-writable for hand editing by members of the `apps` group. The importer sets mode `0664` after writes, and the live files currently have `-rw-rw-r-- apps apps`.

`pending-suggestions.yaml` is normalized into review-friendly key order on every importer run. Match suggestions include Sonarr context fields: `sonarr_library_status` (`present` or `missing`), `sonarr_has_file`, `sonarr_monitored`, and `sonarr_air_date`. The current `Tuuri: Tanssikohtaus` suggestion shows `sonarr_library_status: present` for `S02E01 Dance Mode`.

YLE importer was refactored into a local Python app flake under `pkgs/yle-sonarr-import`. Use `nix develop ./pkgs/yle-sonarr-import -c pytest pkgs/yle-sonarr-import/tests` for fast tests and `nix run ./pkgs/yle-sonarr-import` to run the packaged app. The NixOS service now consumes `inputs.yle-sonarr-import.packages.${system}.default` and keeps only service wiring in `modules/yle-sonarr-import.nix`. Crisuflix was rebuilt/switched after the refactor and `yle-sonarr-import.service` smoke-tested successfully.

`series.yaml` currently contains `bluey-2018` and `alfie-atkins-2012`. Alfie resolved to Sonarr `sonarr_series_id: 160`, and `/var/lib/yle-sonarr-import/alfie-atkins-2012/{mapping,pending-suggestions,state}.yaml` were created. The provided Alfie YLE URL produced 20 pending suggestions, mostly safe `no_match` entries because the YLE metadata appears to include unrelated children's programs; verify the URL before promoting mappings.

## Architecture Principles

- For a Docker-to-Podman migration on crisuflix, treat rootless Podman as per-user socket scope. Dockge, Traefik discovery, `traefik-kop`, Homepage discovery, Dozzle, and Watchtower must read the same Podman socket as the containers they manage/discover.
- Prefer rootless `apps` containers for ordinary services; keep Frigate, WireGuard/SABnzbd network namespace, and ZFS administration as rootful exceptions unless redesigned and tested.
- Do not migrate inactive compose stacks by default; only currently running services are in scope unless explicitly revived.
- Keep the YLE/Sonarr media importer as a deterministic standalone systemd service. AI may propose pending mappings, but only confirmed mapping entries are allowed to trigger downloads/imports.
- For the YLE/Sonarr importer, keep `series.yaml` minimal: top-level key is the Sonarr `titleSlug`; required field is `yle_url`; optional fields include `enabled`, cached `sonarr_series_id`, `language`, and `prompt_hint`. Derive state/download paths from the top-level key.

## Top 3 Next Actions

1. Verify the Alfie YLE URL; current `/var/lib/yle-sonarr-import/alfie-atkins-2012/pending-suggestions.yaml` contains many unrelated `no_match` entries.
2. Review the existing Bluey pending suggestion for `Tuuri: Tanssikohtaus`; likely promote it to `mapping.yaml` as season `2`, episode `1` if confirmed against Sonarr.
3. Continue Podman migration testing: Dockge against a temporary rootless `apps` Podman socket and temporary `/mnt/illby/podman/stacks` tree.

## Blockers

None.
