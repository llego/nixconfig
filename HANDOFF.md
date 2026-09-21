# HANDOFF

Last updated: 2026-09-21 19:11 UTC

## Current State

### Home Assistant

#### Top 3 Next Actions

- Change batteries in the missing Ruuvi tags (`Vardagsrummet`, `Kylskåpet`, `Alvars_rum`), then verify InfluxDB rows and HA sensor recovery.

### Music Assistant

Music Assistant Yamaha/MusicCast debugging is active on `crisuflix`. `hosts/crisuflix/home-automation.nix` now sets `services.music-assistant.extraOptions = [ "--config" "/var/lib/music-assistant" "--log-level" "debug" ];`. Important: `extraOptions` replaces the NixOS module default, so the explicit `--config /var/lib/music-assistant` must stay while debug logging is enabled. `sudo nixos-rebuild switch --flake .#crisuflix` succeeded after staging the file, and `systemctl status music-assistant.service` shows MA running as `/nix/store/.../.mass-wrapped --config /var/lib/music-assistant --log-level debug`. A first incorrect rebuild briefly started MA with only `--log-level debug`, which put MA into setup mode with empty storage; it was immediately corrected and rebuilt. No tracked secrets were added.

Current Yamaha diagnostic facts: AVR direct API at `http://192.168.1.247/YamahaExtendedControl/v1/main/getStatus` returns `"power":"standby"`; model is RX-V6A, firmware/system version `1.80`, API `2.17`, device id `4C22F3A99400`. Music Assistant 2.8.7 uses `aiomusiccast==0.15.0` and polls MusicCast every 10 seconds. The native HA Yamaha MusicCast config entry `01JXA892330HV501YMC2SYPY21` is already disabled by user and `state="not_loaded"`, so it is unlikely to be actively competing. After the corrected MA restart, MA logs show MusicCast loaded and `4C22F3A99400___main/Yamaha MASS` registered at `2026-08-05 09:42:06` local time. HA initially kept `media_player.yamaha_mass` as `unavailable` because HA needed reauthentication to MA; user reauthenticated HA -> MA, and HA now sees `media_player.yamaha_mass` again (`playing` at `2026-08-05 09:49` local time). Remaining investigation is only the Yamaha manual-power-off stale state.

Manual-power-off test with debug logging active did not reproduce the stale-on bug. User played a song on Yamaha MASS, manually powered off the Yamaha, and MA correctly showed the Yamaha as off. Evidence: HA logbook shows `media_player.yamaha_mass` `playing` at `2026-08-05 09:48:21` local time and `off` at `09:50:30`; direct Yamaha API simultaneously returned `"power":"standby"`; MA debug logs show playback started on Yamaha MASS through native MusicCast at `09:45:58` and the Yamaha stream request came from `192.168.1.247`. Leave debug logging active only if more reproduction attempts are desired.

#### Top 3 Next Actions

- Decide whether to keep Music Assistant debug logging temporarily or remove `--log-level debug` from `services.music-assistant.extraOptions` and rebuild `crisuflix`.

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
