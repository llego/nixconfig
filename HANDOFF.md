# HANDOFF

Last updated: 2026-09-25 23:45 UTC

## Current State

### Home Assistant

#### Top 3 Next Actions

- Change batteries in the missing Ruuvi tags (`Vardagsrummet`, `Kylskåpet`, `Alvars_rum`), then verify InfluxDB rows and HA sensor recovery.

### Music Assistant

Music Assistant is now running **2.10.4** in Docker Compose at `/mnt/illby/docker/stacks/music-assistant` on `crisuflix`. The container uses host networking with `/mnt/illby/appstorage/music-assistant` bind-mounted at `/data`, preserving the existing ZFS dataset and library. `ma.cri.su` is routed via traefik-kop Docker labels; the static VPS route was removed. Automatic stable updates are handled by Watchtower.

Yamaha MASS (`4C22F3A99400___main`, RX-V6A at `192.168.1.247`) is **discovered and controllable** — actively playing at verification time. The previous "identical name" mDNS error was caused by both UniFi's mDNS Proxy and `crisuflix`'s Avahi reflector forwarding between Home/IoT VLANs. Fixed by disabling the Avahi reflector (`reflector = false`) on `crisuflix`; UniFi's proxy now handles cross-VLAN discovery. Chromecast (Nest Audio, Android TV) discovery works across VLANs through UniFi's proxy.

**TIDAL remains disabled** in settings. The official 2.10.4 image includes the bundled `app_secrets.json` that was missing from the NixOS package, so the upstream PR #564869 is no longer a blocker for the Docker deployment. TIDAL authentication should be tested by enabling the provider in the MA UI.

#### Top 3 Next Actions

- Enable TIDAL provider in MA UI and verify login/playback with the Docker image's bundled credentials.
- Verify Yamaha standby/wake and long-term reconnection recovery on 2.10.4; consider reducing log level from debug.
- Confirm no regression after next nixpkgs update (the native service is fully removed).

### OpenCloud

As of 2026-09-21, the active service and the repository's evaluated package are both OpenCloud 7.5.0. Upstream has released 8.0.1, but nixos-unstable still lists 7.5.0; no 8.0.x update PR was found during this check. No upgrade or reindex was performed.

Mandatory after upgrading from 7.x to 8.x: run `opencloud search index --all-spaces --force-rescan --insecure` once with the upgraded binary. This is a native NixOS service, not Docker: run as `opencloud:opencloud`, with the same configuration and environment as `opencloud.service` (including `/run/agenix/opencloud-env`) and working directory `/mnt/illby/appstorage/opencloud`. The command shown is the CLI operation, not a complete environment-loading wrapper; inspect the deployed unit when executing it. Do not run it now as an 8.x migration on 7.5.0. Reindexing can run while the service remains available; existing untouched files will not appear in the new search index until reindexed. Verify older files are searchable before removing obsolete indexes, and preserve the current versioned index. Prefer 8.0.1 over 8.0.0 because it fixes a reindex timeout. See the [8.x upgrade guide](https://docs.opencloud.eu/docs/admin/maintenance/upgrade/upgrade-8.x.x). No secrets were added to tracked files.

OpenCloud Android repeated-login issue: OpenCloud external IdP config was aligned with the upstream docs. `hosts/crisuflix/opencloud.nix` now explicitly sets `WEBFINGER_*_OIDC_CLIENT_ID` and `WEBFINGER_*_OIDC_CLIENT_SCOPES` for web, Android, iOS, and desktop clients. `hosts/vps/authelia-cri.su.nix` now defines `lifespans.custom.opencloud_native` with `refresh_token = "365d"` and assigns it to OpenCloud Desktop/Android/iOS. The OpenCloud web client now uses only `grant_types = [ "authorization_code" ]` to avoid Authelia's refresh-token-without-offline-access warning. `crisuflix` and `vps` were rebuilt successfully; OpenCloud is active, `cloud.cri.su` returns 200, and Authelia is active. User successfully logged into the Android app after clearing stale auth state and later verified the Android app stays logged in. No tracked secrets were added.

#### Top 3 Next Actions

- When 8.x becomes available and an upgrade is planned, back up OpenCloud configuration and data before updating the flake lock and deploying.
- After deploying 8.x, run the one-time search reindex above with the upgraded service's user, configuration, and environment.
- Verify older files appear in Web Client search, then remove only obsolete search indexes per the upgrade guide.

### VPS Reverse Proxy

VPS Redis/Traefik startup race fixed and deployed. `hosts/vps/reverse-proxy.nix` now lets `redis-traefik` bind all interfaces with `services.redis.servers.traefik.bind = null`, while Traefik reads the Redis provider through loopback (`127.0.0.1:6379`). This avoids Redis failing to bind before `tailscale0` owns `100.64.0.4`; remote access is still limited by the existing firewall rule that permits only `crisuflix` to reach Redis over Tailscale. `nix eval '.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'` succeeded, and `nixos-rebuild switch --flake .#vps --target-host llego@christiansandberg.fi --sudo` succeeded from `crisuflix`. After the switch, `redis-traefik.service` and `traefik.service` were active, and Traefik logs since restart showed only startup messages with no Redis provider errors. No tracked secrets were added.

#### Top 3 Next Actions

- No immediate follow-up recorded.

## Blockers

- TIDAL authentication awaits the upstream nixpkgs packaging fix described above.
- No secrets were added to tracked files.
