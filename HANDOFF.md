# HANDOFF

Last updated: 2026-10-21 19:02 UTC

## Git Commit Signing

SSH commit signing is configured in the shared core module for `laptop`, `crisuflix`, `vps`, and `rpi5`. A dedicated key is encrypted as `secrets/git-signing-key.age`, and Git signs commits automatically with `/run/agenix/git-signing-key`. The public signing key fingerprint is `SHA256:JP9GsAqW7bAaB7JH57MSA2i8RS3o+M92mq1oiQkvYLw`. A local signed-commit verification test passed, GitHub key ID `1262827`.

### Top 3 Next Actions

- Rebuild the remaining hosts so agenix deploys the signing key and Git configuration there.
- Create and push a signed commit, then verify GitHub marks it as verified.
- Confirm the GitHub account recognizes the first pushed commit as verified.

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

OpenCloud Android repeated-login issue: OpenCloud's WebFinger client IDs/scopes are set in the Compose stack for web, Android, iOS, and desktop. Authelia remains a separate NixOS-managed OIDC provider and defines `lifespans.custom.opencloud_native` with `refresh_token = "365d"`, used by its OpenCloud Desktop/Android/iOS clients. The OpenCloud web client uses only `grant_types = [ "authorization_code" ]` to avoid Authelia's refresh-token-without-offline-access warning. User successfully logged into the Android app after clearing stale auth state and later verified the Android app stays logged in. No tracked secrets were added.

#### Top 3 Next Actions

### VPS Reverse Proxy

VPS Redis/Traefik startup race fixed and deployed. `hosts/vps/reverse-proxy.nix` now lets `redis-traefik` bind all interfaces with `services.redis.servers.traefik.bind = null`, while Traefik reads the Redis provider through loopback (`127.0.0.1:6379`). This avoids Redis failing to bind before `tailscale0` owns `100.64.0.4`; remote access is still limited by the existing firewall rule that permits only `crisuflix` to reach Redis over Tailscale. `nix eval '.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'` succeeded, and `nixos-rebuild switch --flake .#vps --target-host llego@christiansandberg.fi --sudo` succeeded from `crisuflix`. After the switch, `redis-traefik.service` and `traefik.service` were active, and Traefik logs since restart showed only startup messages with no Redis provider errors. No tracked secrets were added.

#### Top 3 Next Actions

- No immediate follow-up recorded.

### Headscale DNS

Headscale now advertises only the Control D DoH endpoint `https://dns.controld.com/wrpogws0c1` as its global resolver. The redundant `76.76.2.22` resolver was removed because multiple global resolvers can bypass Control D restrictions. The VPS was rebuilt using `crisuflix` as the build host and deployed successfully on 2026-09-29. Both the VPS and laptop now report the single Control D resolver; split DNS routes remain unchanged. No tracked secrets were added.

## Blockers
