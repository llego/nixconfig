# HANDOFF

Last updated: 2026-10-12 19:04 UTC

## Current State

### Home Assistant

#### Top 3 Next Actions

- Change batteries in the missing Ruuvi tags (`Vardagsrummet`, `Kylskåpet`, `Alvars_rum`), then verify InfluxDB rows and HA sensor recovery.

### Music Assistant

Music Assistant is now running **2.10.4** in Docker Compose at `/mnt/illby/docker/stacks/music-assistant` on `crisuflix`. The container uses host networking with `/mnt/illby/appstorage/music-assistant` bind-mounted at `/data`, preserving the existing ZFS dataset and library. `ma.cri.su` is routed via traefik-kop Docker labels; the static VPS route was removed. Automatic stable updates are handled by Watchtower.

Yamaha MASS (`4C22F3A99400___main`, RX-V6A at `192.168.1.247`) is **discovered and controllable** — actively playing at verification time. The previous "identical name" mDNS error was caused by both UniFi's mDNS Proxy and `crisuflix`'s Avahi reflector forwarding between Home/IoT VLANs. Fixed by disabling the Avahi reflector (`reflector = false`) on `crisuflix`; UniFi's proxy now handles cross-VLAN discovery. Chromecast (Nest Audio, Android TV) discovery works across VLANs through UniFi's proxy.

#### Top 3 Next Actions

- Verify Yamaha standby/wake and long-term reconnection recovery on 2.10.4; consider reducing log level from debug.

### OpenCloud

As of 2026-10-12, OpenCloud 7.5.0 and Collabora Online run in Docker Compose at `/mnt/illby/docker/stacks/opencloud` on `crisuflix`. OpenCloud uses `opencloudeu/opencloud-rolling:7.5.0`; Collabora currently uses `collabora/code:latest` (26.04.5.1). Both use host networking and traefik-kop labels (`kop.namespace=vps`), with routes publishing `100.64.10.1:9200` and `:9980`. Compose owns the stack's `.env` and reads configuration from `/mnt/illby/docker/data/opencloud/config`; `.env` is mode 0600. The OpenCloud agenix entry and encrypted file, Nix service module, port options, and host UID/GID account have been removed; the obsolete `/etc/opencloud` copy was removed after config hashes matched the Compose copy. Authelia's OIDC client/lifespan settings remain in its NixOS configuration because they configure the separate Authelia identity provider. No OpenCloud service secret/config remains in agenix or tracked Nix files. The original data remains at `/mnt/illby/appstorage/opencloud`, and a ZFS snapshot `illby/appstorage/opencloud@pre-docker-migration-2026-10-12` was taken before migration. Local OpenCloud and Collabora endpoints return HTTP 200; public hostnames also return 200 through the currently active VPS routes.

OpenCloud's Homepage card is now defined by Compose labels (`homepage.group/name/description/icon/href`) and the static item was removed from `hosts/vps/homepage.nix`. The running container's labels were verified. The Homepage Nix change is not deployed yet, so its existing static card may remain until a safe VPS rebuild.

The VPS static routes have been removed from `hosts/vps/reverse-proxy.nix` but this change has **not yet been deployed**. The running VPS Traefik still has the old static routes. Deployment is intentionally waiting until it will not interrupt a friend's Jellyfin stream. When safe, rebuild the VPS from `crisuflix`, then verify both public hosts are served by the Redis/KOP routes and test an actual document edit.

Mandatory after upgrading from 7.x to 8.x: run `docker compose run --rm opencloud search index --all-spaces --force-rescan --insecure` once with the upgraded image and its Compose environment/config. Do not run this as an 8.x migration on 7.5.0. Reindexing can run while the service remains available; existing untouched files will not appear in the new search index until reindexed. Verify older files are searchable before removing obsolete indexes, and preserve the current versioned index. Prefer 8.0.1 over 8.0.0 because it fixes a reindex timeout. See the [8.x upgrade guide](https://docs.opencloud.eu/docs/admin/maintenance/upgrade/upgrade-8.x.x). No secrets were added to tracked files.

OpenCloud Android repeated-login issue: OpenCloud's WebFinger client IDs/scopes are set in the Compose stack for web, Android, iOS, and desktop. Authelia remains a separate NixOS-managed OIDC provider and defines `lifespans.custom.opencloud_native` with `refresh_token = "365d"`, used by its OpenCloud Desktop/Android/iOS clients. The OpenCloud web client uses only `grant_types = [ "authorization_code" ]` to avoid Authelia's refresh-token-without-offline-access warning. User successfully logged into the Android app after clearing stale auth state and later verified the Android app stays logged in. No tracked secrets were added.

#### Top 3 Next Actions

- After the current Jellyfin viewing session, deploy the VPS reverse-proxy change that removes the static OpenCloud/Collabora routes; verify cloud.cri.su and office.cri.su are served by traefik-kop/Redis.
- Test document editing end-to-end (including Collabora WebSockets), and confirm existing files and mobile/native client sign-in still work.
- Before any later OpenCloud 8.x upgrade, back up configuration/data; then run the required one-time `opencloud search index --all-spaces --force-rescan --insecure` and verify older files are searchable before removing obsolete indexes.

### VPS Reverse Proxy

VPS Redis/Traefik startup race fixed and deployed. `hosts/vps/reverse-proxy.nix` now lets `redis-traefik` bind all interfaces with `services.redis.servers.traefik.bind = null`, while Traefik reads the Redis provider through loopback (`127.0.0.1:6379`). This avoids Redis failing to bind before `tailscale0` owns `100.64.0.4`; remote access is still limited by the existing firewall rule that permits only `crisuflix` to reach Redis over Tailscale. `nix eval '.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'` succeeded, and `nixos-rebuild switch --flake .#vps --target-host llego@christiansandberg.fi --sudo` succeeded from `crisuflix`. After the switch, `redis-traefik.service` and `traefik.service` were active, and Traefik logs since restart showed only startup messages with no Redis provider errors. No tracked secrets were added.

#### Top 3 Next Actions

- No immediate follow-up recorded.

### Headscale DNS

Headscale now advertises only the Control D DoH endpoint `https://dns.controld.com/wrpogws0c1` as its global resolver. The redundant `76.76.2.22` resolver was removed because multiple global resolvers can bypass Control D restrictions. The VPS was rebuilt using `crisuflix` as the build host and deployed successfully on 2026-09-29. Both the VPS and laptop now report the single Control D resolver; split DNS routes remain unchanged. No tracked secrets were added.

## Blockers
