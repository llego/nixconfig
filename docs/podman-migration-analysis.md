# Crisuflix Podman Migration Analysis

Last updated: 2026-06-24

Host inspected: `crisuflix`

Planned migrated config/runtime root: `/mnt/illby/podman`

Current Docker roots in use:

- Dockge install: `/mnt/illby/docker/dockge/compose.yaml`
- Dockge-managed stacks: `/mnt/illby/docker/stacks`
- App data: `/mnt/illby/docker/data`
- Shared app storage: `/mnt/illby/appstorage`

This analysis intentionally considers only containers currently running under Docker. Stacks present on disk but not currently running can be disregarded for the migration unless they are intentionally revived later.

## Summary

Migrating most services from Docker to rootless Podman under the `apps` user is plausible, but the migration should be treated as a runtime/API migration, not only as a compose-file migration.

The highest-risk pieces are the Docker socket consumers:

- Dockge
- Traefik local Docker provider
- `traefik-kop`
- Homepage auto-discovery
- Dozzle
- Watchtower
- Any future monitoring/control container that talks to `/var/run/docker.sock`

Labels are not the main problem. Compose labels for Traefik and Homepage should mostly survive if the component reading them can see the containers through a Docker-compatible API socket. The real issue is which Podman socket each tool reads and whether that tool handles Podman's Docker API compatibility layer well enough.

## Upstream Support Research

### Dockge

Source checked: `https://github.com/louislam/dockge` README and GitHub issues returned by `repo:louislam/dockge podman`.

Findings:

- Dockge now explicitly lists `Docker 20+ / Podman` as a requirement.
- For Podman, the README says `podman-docker` is required.
- Dockge describes itself as a `docker compose.yaml` stack manager and says normal `docker compose` commands should work against the same files.
- The README still uses `/var/run/docker.sock:/var/run/docker.sock` in its compose examples.
- Open issue `#361` reports Dockge calling `docker compose ps --format json`, which did not map cleanly to `podman-compose` in that user's setup.
- Issue `#444` documented missing Podman compose-provider requirements; this is why `podman-compose`/compat tooling matters.
- Open issue `#657` reports Podman behavior problems on macOS when replacing containers. That is macOS-specific, but it confirms Podman support is not equivalent to native Docker support in all workflows.

Interpretation for NixOS/crisuflix:

- Dockge is not Docker-only anymore, but Podman support depends on providing a Docker-compatible CLI and socket.
- On NixOS the relevant equivalent to `podman-docker` is `virtualisation.podman.dockerCompat = true`, plus ensuring compose support is available. `podman-compose` exists in nixpkgs; currently indexed version is `1.5.0` on unstable.
- Dockge should first be tested against a temporary rootless `apps` Podman socket and temporary stack root before touching the real stacks.
- If Dockge runs as a container under `apps`, it should mount the `apps` user's Podman socket as `/var/run/docker.sock` inside the container.
- Do not point one Dockge instance at both rootless and rootful Podman sockets unless upstream multi-agent behavior is explicitly tested for that split. Prefer one rootless Dockge agent for the `apps` rootless world and handle rootful exceptions separately.

### traefik-kop

Source checked: `https://github.com/jittering/traefik-kop` README and GitHub issues returned by `repo:jittering/traefik-kop podman`.

Findings:

- `traefik-kop` documents itself as a dynamic `docker -> redis -> traefik` discovery agent.
- It expects the Docker API, defaulting to `unix:///var/run/docker.sock`.
- The Docker API socket path can be changed with `DOCKER_ADDR` or `--docker-host`.
- The README says non-unix Docker API connection methods like SSH and HTTP are not supported by `traefik-kop`.
- GitHub issue `#9` says the reporter ran it with Podman by mounting the Podman socket into the container as the Docker socket, and that this worked, but healthcheck transitions were not always picked up.
- GitHub issue `#24` says a reported bug was not caused by Podman and that `traefik-kop` worked on an Alpine machine with Podman. The same issue shows Podman socket mounting as `/var/run/docker.sock`.

Interpretation for crisuflix:

- `traefik-kop` appears likely to work with Podman's Docker-compatible socket, but it is not documented as first-class Podman support.
- Keep `KOP_POLL_INTERVAL` enabled. Your current value is `10`, which is good because polling mitigates missed Docker/Podman event transitions.
- Publicly routed containers should use explicit `traefik.http.services.<service>.loadbalancer.server.port` labels after migration. `traefik-kop` can infer a single published port, but Podman compatibility reports make explicit port labels safer.
- If most containers run rootless as `apps`, `traefik-kop` must read the `apps` user's Podman socket to discover them. A rootful `traefik-kop` reading only `/run/podman/podman.sock` will not see rootless `apps` containers.

### Traefik Docker Provider With Podman

Source checked: Traefik Docker provider docs and Podman `podman system service` docs.

Findings:

- Traefik's Docker provider reads labels through the Docker API.
- Traefik docs explicitly mention `host.containers.internal` as the Podman equivalent of `host.docker.internal` for host-networked containers.
- Podman `podman system service` provides a Docker v1.40 compatibility API.
- Rootful Podman socket: `/run/podman/podman.sock`.
- Rootless user Podman socket: `$XDG_RUNTIME_DIR/podman/podman.sock`, normally `/run/user/<uid>/podman/podman.sock`.
- Podman docs say containers that access the Podman API socket should mount the socket and use `--security-opt label=disable`.

Interpretation for crisuflix:

- A rootless Traefik container can discover rootless `apps` containers if it mounts the `apps` user's Podman socket as `/var/run/docker.sock` and has label separation equivalent to the current `traefik.instance=internal` constraint.
- If Traefik must bind `80` and `443`, either keep Traefik rootful or add a deliberate host-level low-port solution. Do not assume rootless low-port binding will work by default.

## Current Active Compose Projects

Active compose project names from running containers:

- `arr`
- `arr-stack`
- `beets-flask`
- `beszel`
- `changedetection`
- `dockge`
- `dozzle`
- `frigate`
- `grafana`
- `grimmory`
- `ha-mcp`
- `ihatemoney`
- `immich`
- `influxdb`
- `jellyfin-official`
- `kms`
- `notesnook`
- `open-webui`
- `readeck`
- `reitti`
- `tidarr`
- `traefik`
- `traefik-kop`
- `watchtower`
- `zfdash`

Running non-compose/NixOS OCI container:

- `homeassistant`, from `modules/home-automation.nix`, currently `virtualisation.oci-containers.backend = "docker"`

## Rootless Target Model

Preferred model:

- Enable Podman on NixOS.
- Run most migrated compose stacks rootless under user `apps`.
- Enable lingering for `apps` so rootless containers and `podman.socket` survive logout/reboot.
- Use `/mnt/illby/podman/stacks` as the new Dockge stack root.
- Use `/mnt/illby/podman/dockge` for Dockge's own config/data if Dockge is migrated too.
- Keep persistent application data where it is unless there is a reason to move it. Moving compose files to `/mnt/illby/podman` does not require moving all databases/media/config volumes at the same time.

Likely NixOS concepts involved:

- `virtualisation.podman.enable = true`
- `virtualisation.podman.dockerCompat = true`
- `virtualisation.oci-containers.backend = "podman"` for NixOS-managed OCI containers, if Home Assistant is migrated through the NixOS module
- User-level `podman.socket` for `apps`
- Possibly rootful `podman.socket` for the few rootful exceptions

Do not use Home Manager for this host.

## Planned Directory Layout

Suggested layout:

```text
/mnt/illby/podman/
  dockge/
    compose.yaml
    data/
  stacks/
    traefik/
      compose.yaml
    traefik-kop/
      compose.yaml
    ha-mcp/
      compose.yaml
    ...
```

For Dockge, the stack path must be identical on the host and inside the Dockge container. The current Docker install already follows this rule with `/mnt/illby/docker/stacks:/mnt/illby/docker/stacks`. The Podman equivalent should use `/mnt/illby/podman/stacks:/mnt/illby/podman/stacks` and `DOCKGE_STACKS_DIR=/mnt/illby/podman/stacks`.

## Containers That Definitely Require Rootful Mode Under Current Design

These are the containers that should not be first-wave rootless migrations. They either currently request privileged mode, host-level network administration, or sensitive host device/system access.

| Container | Compose project | Why rootful under current design |
| --- | --- | --- |
| `frigate` | `frigate` | Current compose has `privileged: true`, passes `/dev/bus/usb` for Coral, passes `/dev/dri`, and publishes RTSP/WebRTC ports. This is a rootful island unless the Frigate hardware access model is redesigned and tested. |
| `wireguard-mullvad` | `arr-stack` | Requires `NET_ADMIN`, WireGuard networking, sysctl `net.ipv4.conf.all.src_valid_mark=1`, and owns the network namespace used by `sabnzbd`. Treat as rootful unless replaced with a host-level VPN/tunnel design. |
| `sabnzbd` | `arr-stack` | Uses `network_mode: service:wireguard-mullvad`, so it is tied to the WireGuard container's namespace. If `wireguard-mullvad` remains rootful, `sabnzbd` should stay with it. |
| `zfdash` | `zfdash` | Passes `/dev/zfs`, mounts `/dev/disk`, `/run/udev`, host `/etc`, and root SSH material. This is host administration, not an ordinary app container. Keep rootful or replace with a safer native/NixOS monitoring approach. |

## Containers That Are Not Definitely Rootful But Need Special Testing

| Container/project | Concern | Recommended approach |
| --- | --- | --- |
| `traefik` | Binds ports `80`, `443`, and `8080`; reads container socket. | Either keep rootful, or implement an explicit low-port strategy and mount the `apps` Podman socket. Test internal routing before public migration. |
| `traefik-kop` | Must read the same socket as the containers it publishes. | Can likely run rootless under `apps` if it only publishes rootless `apps` containers. Use the `apps` socket and keep `KOP_POLL_INTERVAL=10`. |
| `dockge` | Must control the target Podman environment and run compose operations. | Test rootless Dockge with the `apps` Podman socket and `/mnt/illby/podman/stacks`. Verify `docker compose ps --format json` behavior through NixOS compat tooling. |
| `dozzle` | Reads container socket and has actions enabled. | Rootless is reasonable if pointed at the `apps` Podman socket; it will only see/control that user's containers. |
| `watchtower` | Reads and mutates containers through socket. | Prefer replacing with explicit update workflow. If kept, run one instance per socket scope. |
| `homeassistant` | Host networking and `/dev/ttyUSB0` serial device via NixOS OCI container. | Could be migrated to Podman backend separately, but test serial permissions, host networking, and integrations before moving. |
| `immich_server` | Passes `/dev/dri` for hardware acceleration. | Rootless may work if `apps` has render/video permissions and device access is configured. Test transcoding. |
| `jellyfin` | Passes `/dev/dri` for hardware acceleration. | Rootless may work if `apps` has render/video permissions and device access is configured. Test VAAPI/QSV playback/transcoding. |
| `glances` | Uses `pid: host`, mounts `/`, and reads container socket in the old stack. | There is already a native NixOS Glances service in the repo. Prefer native service over migrating this container. |

## Good Rootless Candidates

These currently have no obvious privileged/device/network-admin requirements in the inspected runtime data. They may still need volume ownership fixes because rootless Podman will not behave exactly like Docker's rootful bind mounts.

- `ha-mcp`
- `prowlarr`
- `radarr`
- `sonarr`
- `grimmory`
- `reitti-postgis`
- `notesnook-monograph`
- `notesnook-events`
- `notesnook-server`
- `notesnook-auth`
- `notesnook-s3`
- `notesnook-db`
- `tidarr`
- `readeck`
- `open-webui`
- `immich_db_dumper`
- `immich_postgres`
- `immich_machine_learning`
- `immich_redis`
- `ihatemoney`
- `mariadb` for `grimmory`
- `grafana`
- `changedetection`
- `beszel`
- `kms`
- `kms-gui`
- `influxdb`
- `reitti`
- `reitti-redis-1`
- `reitti-tile-cache`
- `beets-flask`

Notes:

- `beets-flask` currently runs as `root` inside the container and writes across music/import paths. It is not necessarily rootful at the Podman runtime level, but its file ownership behavior should be reviewed before switching.
- LinuxServer.io containers using `PUID=568`/`PGID=568` are conceptually aligned with the `apps` user, but rootless bind mount ownership still needs live testing.
- Database containers should be stopped cleanly and migrated one at a time.

## Traefik And Homepage Labels

The label strategy can continue, with some cleanup.

For Traefik:

- Keep `traefik.enable=true`.
- Keep `traefik.instance=internal` / `public` split if local Traefik and `traefik-kop` remain side by side.
- Add explicit `traefik.http.services.<service>.loadbalancer.server.port=...` to every public `kop.namespace=vps` service before migration, especially services with multiple published ports or non-obvious image `EXPOSE` metadata.
- For public `traefik-kop` routes, the service port should be the host-reachable published port, not merely the internal container port, unless testing proves the Podman socket path preserves the current behavior.

For Homepage:

- Existing `homepage.*` labels should remain usable if Homepage can read the same Podman socket as the rootless containers.
- A Homepage instance reading the rootful socket will not see rootless `apps` containers, and a Homepage instance reading the `apps` socket will not see rootful exceptions.
- If a single dashboard must show both, prefer static Homepage entries for rootful exceptions or run discovery through a carefully scoped architecture. Avoid exposing a rootful control socket just for convenience.

## Socket Scope Decision

Rootless Podman is per-user. This is the most important design difference from one global Docker daemon.

If most stacks run as `apps`, then these should point at the `apps` user's socket:

- Dockge managing `/mnt/illby/podman/stacks`
- local Traefik discovering internal `apps` containers
- `traefik-kop` publishing public `apps` containers to Redis
- Homepage auto-discovery for `apps` containers
- Dozzle if retained
- Watchtower if retained

Rootful exceptions will not appear in that socket. For rootful exceptions, use one of these patterns:

1. Static Traefik routes and static Homepage entries for the exceptions.
2. A separate rootful discovery/control stack, only if there is a clear need.
3. Keep Docker temporarily for rootful exceptions during phased migration.

The safest initial split is: rootless `apps` for ordinary apps, static config for rootful exceptions.

## Migration Order

Recommended order:

1. Create `/mnt/illby/podman/stacks` and `/mnt/illby/podman/dockge`.
2. Enable Podman and Docker-compatible tooling on NixOS while leaving Docker enabled.
3. Enable `apps` user lingering and user `podman.socket`.
4. Start a temporary test Dockge against a temporary stack directory and the `apps` Podman socket.
5. Test one trivial labeled container through rootless Podman, local Traefik discovery, and Homepage discovery.
6. Test `traefik-kop` against the `apps` Podman socket with one non-critical public service and verify Redis/VPS Traefik routing.
7. Migrate simple rootless candidates in small groups.
8. Migrate database-backed stacks one at a time with clean shutdown and rollback notes.
9. Handle hardware/network-admin/rootful exceptions last.
10. Remove Docker only after Dockge, Traefik, `traefik-kop`, Homepage, and backups have all been validated against the final Podman layout.

## Open Questions Before Implementation

- Should rootful exceptions remain as Docker containers temporarily, or move to rootful Podman immediately after rootless apps are proven?
- Should Watchtower be retained, replaced by Dockge/manual updates, or replaced by a declarative update process?
- Should local containerized Glances be retired in favor of the existing native NixOS Glances service?
- Should Home Assistant remain NixOS-managed via `virtualisation.oci-containers`, or move under Dockge with the rest of the compose-managed containers?
- Should `/mnt/illby/docker/data` be renamed later, or kept as the persistent app-data root to avoid an unnecessary data move?

## Secrets Note

Some compose files reference secrets through environment interpolation and one active compose file contains at least one hard-coded widget token. Do not copy secret values into new tracked files. During migration, preserve references through external env files or agenix-managed files rather than committing rendered secrets.
