# HANDOFF

Last updated: 2026-11-25 21:07 UTC

## Current State

### Local Home Assistant Proxy

Adapted and started `/mnt/illby/docker/stacks/traefik` as a local Home HTTPS proxy, with dedicated Docker IPv4 and IPv6 networks and a route for `ha.cri.su` to Home Assistant. Previous Compose files are backed up as `compose.yaml.pre-local-20261125` and `compose.yaml.pre-ipv6-20261125`. UniFi advertises Home ULA `fdad:3928:7958:1::/64`; `crisuflix` statically uses `fdad:3928:7958:1::101` on `br0`. Traefik listens on that address and `192.168.1.101` on ports 80 and 443. Its dashboard at `https://traefik-local.cri.su/dashboard/` is restricted to the Home IPv4 and ULA subnets, without separate authentication. The user approved a Home Assistant restart; existing trusted proxies were preserved and `10.253.252.2/32` added via the HTTP settings API, then the configuration was promoted. The Home-only Control D profile now returns both local addresses; rpi5 resolved and reached HA over both IPv4 and IPv6 with HTTP 200. Rpi5 also reached the dashboard over ULA IPv6 with certificate verification. Public DNS still returned the VPS IPv6 address. Client login/WebSocket behavior and proxy reboot recovery remain unverified. No secrets were added to tracked files.

Home Assistant's Compose stack now adds `traefik.instance=internal`, allowing local Traefik to reuse the existing public route and service labels; the duplicate file-based HA route was removed. Local Traefik's default HTTPS entrypoint and `host.docker.internal` mapping route the host-networked HA container to `10.253.252.1:8123`. Both Compose files have `compose.yaml.pre-ha-labels-20261125` backups. After recreating HA and Traefik, the local dashboard showed the HA route only as `home-assistant@docker`; local IPv4, local IPv6, and public VPS HTTPS returned 200, and the dashboard returned 200 over local IPv6. The user confirmed dashboard access from the laptop. Full HA login/WebSocket and reboot testing remain outstanding.

Jellyfin's Compose stack now also sets `traefik.instance=internal`, and local Traefik is attached to `jellyfin-official_default` to reach the container using its existing route labels. The user created the Home Control D rule for `jellyfin.cri.su`; local A and AAAA resolve to the Home proxy. After recreating Traefik and Jellyfin, the local Docker route selected `172.22.0.2:8096`, and local IPv4, local IPv6, and public VPS HTTPS returned 302; following the local IPv6 redirect returned 200. Certificate issuance and VPS route publication briefly lagged startup but subsequently succeeded. Playback and login remain untested. Compose backups are `traefik/compose.yaml.pre-jellyfin-20261125` and `jellyfin-official/compose.yaml.pre-local-proxy-20261125`. No secrets added to tracked files.

The preferred future structure is a shared `traefik-internal` Docker network: local Traefik joins it once, and each application opts in through its own Compose network attachment and labels, retaining any application-specific networks. Add boot-time creation of `traefik-internal` to `hosts/crisuflix/default.nix` before migrating Jellyfin to the shared network, then explicitly select that network for its local Traefik route and verify local and VPS access. This is planned only; it has not been created or deployed. Containers on the shared network may be able to reach one another directly, so attach only intended services.

#### Top 3 Next Actions

- Add declarative `traefik-internal` network creation to `hosts/crisuflix/default.nix`, then migrate and verify Jellyfin on the shared network.
- Test Home Assistant login/WebSockets and Jellyfin login/playback locally and from an independently connected away client.
- Test lab reachability and DNS64 behavior separately if desired; verify proxy, network, and ULA recovery after reboot.

Blockers: Automatic proxy failover remains unimplemented; away-client testing is outstanding.

### IPv6 Lab NAT64

Added and deployed `hosts/crisuflix/nat64-lab.nix`: Jool NAT64 in a dedicated network namespace, with host-side nftables boundary filtering and IPv4 masquerading. The boundary is scoped to interfaces and `64:ff9b::/96`, not the ISP-delegated lab prefix. UniFi routes that prefix to crisuflix's Home link-local address and has an Internal → External lab allow before a catch-all NAT64 drop, plus an Untrusted → External NAT64 drop. Trusted Home devices may bypass UniFi via a direct route to crisuflix; this tradeoff is accepted but the bypass has not been tested. After deployment, Winamp and DuckDuckGo returned HTTP 200 via DNS64/NAT64 from the lab laptop with Tailscale up; router-originated NAT64 also returned 200. Normally routed Home requests timed out and the Internal drop counter increased. On IoT Wi-Fi with Tailscale up, a forced NAT64 request timed out and the Untrusted drop counter rose from 2 to 6. Service, Docker and Tailscale were active with no failed units. Initial activation failed because modprobe searched the booted generation; fixed by selecting the current generation's matching module tree. The new file is staged for flake visibility. No secrets added to tracked files.

#### Top 3 Next Actions

- If practical, test the accepted direct Home bypass and external IPv6 exposure.
- Verify NAT64 service recovery after reboot and UniFi lab-network matching after ISP prefix changes.
- Test additional lab applications and confirm DNS and filtering behavior when roaming.

Blockers: External exposure and reboot/renumbering recovery remain unverified.

### VPS Native IPv6

Configured Hetzner-assigned `2a01:4f9:c010:803e::1/64` and gateway `fe80::1` on `enp1s0` in `hosts/vps/ddns.nix`. Deployed successfully. Outbound IPv6 HTTPS and direct IPv6 HTTPS to `christiansandberg.fi` returned 200; its IPv4 HTTPS also returned 200. Public IPv6 access to `opencode.vpn.cri.su` returned 403. Core services are active and systemd reports no failed units. Published and configured hetzner_ddns to manage apex AAAA records for `cri.su`, `christiansandberg.fi`, `sandbergs.fi`, `crisusandberg.fi`, and `csandberg.fi`; authoritative DNS and 1.1.1.1 return the address, and DDNS validated all records. Some local negative DNS caches may persist temporarily. No subdomain records changed. No secrets added to tracked files. The running VPS kernel remains 6.18.59; the deployed generation includes 6.18.63 and needs a planned reboot to activate it.

Added and deployed dnsmasq `local=/vpn.cri.su/` in `hosts/vps/headscale.nix`, preventing private non-A DNS queries from leaking upstream. Verified private A returns `100.64.0.4`, AAAA and TXT return no records locally, unrelated public DNS resolves, private OpenCode returns 200 over Tailscale IPv4, and direct public IPv6 returns 403. dnsmasq, Headscale and Traefik are active.

Set and deployed Headscale `dns.override_local_dns = false`. General queries now use each client's local network DNS, with the configured Control D endpoint as fallback; split DNS and MagicDNS remain enabled. On the lab laptop, DNS64/NAT64 reaches Winamp and DuckDuckGo with Tailscale connected; OpenCode, `unifi.home`, and tailnet MagicDNS resolve and OpenCode returns 200. Rpi5 resolves crisuflix MagicDNS. Verify DNS and filtering when roaming; this intentionally changes general DNS behavior tailnet-wide.

Published `*.cri.su` AAAA pointing to the VPS and deployed hetzner_ddns management for the wildcard. Authoritative DNS returns the IPv6 address for both `id.cri.su` and public `opencode.vpn.cri.su`; private dnsmasq still returns only `100.64.0.4` for the latter. Verified public IPv6 `id.cri.su` returns 200, public IPv6 OpenCode returns 403, and tailnet IPv4 OpenCode returns 200. DDNS is active and has validated the wildcard. DNS caches may delay client visibility. No secrets added to tracked files.

#### Top 3 Next Actions

- Verify all apex domains from the IPv6-only laptop once cached DNS answers expire.
- Verify wildcard DNS and public and private service access from the IPv6-only laptop after caches expire.
- Plan a VPS reboot for the new kernel and verify IPv4, IPv6, and service recovery afterward.

Blockers: A planned VPS reboot is needed for the new kernel.

### Spliit: Bojvägen Migration

Imported all 1,995 EUR expenses from IHateMoney project `bojvagen` into the user's existing empty Bojvägen Spliit group, preserving its Crisu/Ona participants. Verified every expense through the running app's JSON export: descriptions, amounts, expense/creation dates, payers, and splits match the source. Total €147,607.51; Ona owes Crisu €494.15. IHateMoney's exact balance was €494.145; Spliit apportions whole cents per expense, so imported expense IDs alternate odd-cent tie allocation to prevent cumulative rounding drift while retaining equal splits.

IHateMoney is unchanged. Its consistent SQLite backup passed integrity checking and is stored with a mode-600 migration manifest under `/home/llego/.local/share/ihatemoney-backups/bojvagen-pre-spliit-20261109T095845Z.*`. No Spliit backup was made, per user request. No blockers or secrets added to tracked files; group/participant capability IDs are kept out of this repository.

#### Top 3 Next Actions

- Refresh Spliit and confirm the imported group and balance in the UI.
- Use Spliit for new expenses; keep IHateMoney available until satisfied with the migration.
- Include Spliit's database in routine backups if adopting it long-term.

### OpenCode V2 Server

Added `hosts/crisuflix/opencode.nix`: systemd-managed shared server as `llego`,
using existing config, provider credentials, and sessions. Binds only to the
crisuflix tailnet IP on TCP 49374 with a readiness wait and tailnet-interface
firewall opening. Uses supported service commands to persist hostname, port,
and password, disables OpenTunnel, and registers the foreground process for
local CLI discovery/pairing. Existing server password encrypted to crisuflix
and the recovery user in `opencode-server-env.age`; MCP secrets are supplied via
systemd credentials. No plaintext secrets added to tracked files.

Added VPS Traefik route `https://opencode.vpn.cri.su`, protected by `tailnet-only`
and the existing centralized public-access guard. Full crisuflix and VPS builds
passed. Both hosts are deployed; `opencode.service` is active on crisuflix.
Public-IP HTTPS returns 403. User confirmed successful pairing and use from
both the Android phone app and web browser. The OpenCode link under Homepage's
Tools section is also deployed on VPS. See `docs/opencode.md` for activation,
pairing, and verification. No blockers or plaintext secrets added to tracked files.

#### Top 3 Next Actions

- Verify recovery and client reconnection after a future service/host restart.
- Confirm unauthenticated API rejection and no LAN access to the backend.
- Consider a consistent backup of the OpenCode session database and credentials.

### Pocket ID Backups

`hosts/vps/pocketid.nix` now declares a daily Restic backup that streams `pocket-id export --path -` into `pocket-id-export.zip`, without stopping Pocket ID or writing a temporary archive. The backup inherits the server's environment files, encryption-key credential and working directory. Its separate encrypted repository targets the dedicated Hetzner bucket at `s3:https://hel1.your-objectstorage.com/vps-pocket-id`, retaining 30 daily and 12 monthly snapshots. The existing Hetzner credentials and Restic password were scoped and re-encrypted for both `crisuflix` and `vps`; agenix recipient checks pass. User created the bucket and deployed the VPS configuration. No plaintext secrets were added to tracked files.

#### Top 3 Next Actions

- Confirm the first scheduled timer run succeeds after the verified manual run.
- Add backup failure notifications if desired.
- Test a restore/import in an isolated Pocket ID instance, using the original encryption key; upstream still labels export/import experimental. Keep access to the agenix recovery identity and repository password independent of Pocket ID.

The full VPS system build and `git diff --check` passed. Manual backup on 2026-11-05 succeeded (service result `success`, exit 0), initializing the repository and saving snapshot `974365fa` with a 2.526 MiB export. `restic check --read-data` found no errors. Downloading the export into memory verified all ZIP CRCs and valid `database.json` (37 archive entries, 11 database tables); no plaintext export was saved to disk. Pocket ID remained active. Next timer run was 2026-11-06 04:03 EET. No blockers; a full isolated import/restore test remains outstanding.

### VPS Reverse Proxy

Added a centralized `vpn-block-public` HTTPS router in `hosts/vps/reverse-proxy.nix`. It matches `*.vpn.cri.su` requests whose direct client IP is outside `100.64.0.0/10` and returns 403 through the existing `tailnet-only` middleware, using `noop@internal` as the unused service. Priority `1000000` is reserved above service routers, including Redis routes; tailnet clients skip the guard. Existing per-service restrictions remain. The full VPS system build and `git diff --check` passed; not deployed yet. No secrets were added to tracked files. No blockers.

#### Top 3 Next Actions

- Deploy the VPS configuration.
- Verify private hostnames return 403 through the public VPS IP and remain reachable through the tailnet IP.
- Confirm public services are unaffected and retain service-router priorities below the guard.

VPS Redis/Traefik startup race fixed and deployed. `hosts/vps/reverse-proxy.nix` now lets `redis-traefik` bind all interfaces with `services.redis.servers.traefik.bind = null`, while Traefik reads the Redis provider through loopback (`127.0.0.1:6379`). This avoids Redis failing to bind before `tailscale0` owns `100.64.0.4`; remote access is still limited by the existing firewall rule that permits only `crisuflix` to reach Redis over Tailscale. No immediate follow-up recorded.
