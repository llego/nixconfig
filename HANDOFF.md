# HANDOFF

Last updated: 2026-09-23 19:05 UTC

## Current State

### Home Assistant

#### Top 3 Next Actions

- Change batteries in the missing Ruuvi tags (`Vardagsrummet`, `Kylskåpet`, `Alvars_rum`), then verify InfluxDB rows and HA sensor recovery.

### Music Assistant

Music Assistant is now running **2.10.3** on `crisuflix`, verified from the active systemd command after its restart at 2026-09-23 21:48 EEST (18:48 UTC). Persistent data remains at `/mnt/illby/appstorage/music-assistant`, mounted at `/var/lib/music-assistant` inside the service. `hosts/crisuflix/home-automation.nix` retains `services.music-assistant.extraOptions = [ "--config" "/var/lib/music-assistant" "--log-level" "debug" ];`. Important: `extraOptions` replaces the NixOS module default, so preserve the explicit config path; omitting it previously caused MA to start with empty storage in setup mode.

Yamaha MASS (`4C22F3A99400___main`, RX-V6A at `192.168.1.247`) repeatedly became unavailable **inside Music Assistant itself**, requiring a MusicCast provider reload. Logs show unavailability and rediscovery on September 20, then a provider reload at September 21 21:11:27 EEST followed by playback at 21:11:34. Source inspection of the then-installed 2.9.13 found that rediscovered replacement players were not marked initialized, excluding them from normal player listings; 2.10.3 fixes that registration path. It also removes the busy-lock early return that could silently skip MusicCast polling (upstream PR #5517). These are relevant fixes, but the exact incident cause and successful long-term recovery after the upgrade remain unverified. If it recurs, capture MA availability/logs and direct Yamaha HTTP/UPnP reachability before reloading. Native HA MusicCast was previously disabled; the earlier HA-to-MA reauthentication issue was separate.

**TIDAL is blocked after the upgrade:** both saved-token refresh and new login fail with HTTP 400, `invalid_request, Missing parameters: client_id`. The installed 2.10.3 expects bundled application credentials, but its `app_secrets.json` is absent; the current nixos-unstable recipe builds from GitHub source without provisioning that bundle. [nixpkgs PR #564869](https://github.com/NixOS/nixpkgs/pull/564869), “music-assistant: fix librespot patch, fix missing client_id”, was still open/unmerged when checked on September 23. **User chose to wait for the upstream fix** rather than apply a local workaround. Updating nixpkgs again will help only once the fix reaches nixos-unstable. No local credential overrides or service changes were made during this investigation.

#### Top 3 Next Actions

- Wait for PR #564869 to merge and reach nixos-unstable; then update the nixpkgs input and rebuild/deploy `crisuflix`.
- Verify TIDAL's saved session refreshes with the fixed package; reauthenticate only if still required, then test playback.
- Verify Yamaha standby/wake and reconnection recovery on 2.10.3; retain debug logs until checked, then consider removing debug logging while preserving `--config /var/lib/music-assistant`.

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
