# OpenCode V2 server

`hosts/crisuflix/opencode.nix` runs the shared OpenCode server as `llego` under
systemd. It uses the existing home directory, config, provider credentials, and
session database. This is a personal agent server, not a sandbox: agents have
the same account access as local OpenCode sessions.

The backend binds only to `100.64.10.1:49374`, after waiting for Tailscale. The
VPS proxies `https://opencode.vpn.cri.su` to it over the tailnet, using the
`tailnet-only` middleware and centralized private-hostname guard. HTTPS serves
both the web UI and API; no extra CORS origins or external authentication proxy
are needed for the same-origin UI and native app.

## Activation

Run from `/home/llego/nixconfig` on crisuflix:

```sh
hostname
nixos-rebuild switch --flake .#vps --target-host llego@christiansandberg.fi --sudo
sudo nixos-rebuild switch --flake .#crisuflix
```

**The first crisuflix activation interrupts the existing background server and
its connected clients.** Run it from a separate SSH shell, not through an agent
using that server. The service uses supported `opencode service` commands to
set the listening address, port, and password, and disable OpenTunnel. It then
runs `opencode serve --service` in the foreground so local CLI discovery and
pairing use the same systemd-managed process. Do not use `opencode service
restart` to manage it; use `sudo systemctl restart opencode` instead.

The encrypted `secrets/opencode-server-env.age` supplies the existing stable
password through agenix, preserving already-paired clients. No password is
stored in the Nix store. Rotate this secret and restart the systemd service to
change the password; this signs existing clients out. MCP credentials are
supplied through systemd credentials rather than relying on shell startup.

## Connect

With Tailscale connected on the client, run this as `llego` on crisuflix:

```sh
opencode pair --url https://opencode.vpn.cri.su
```

Open the link in a browser, or scan the QR code with the OpenCode Android app
(pasting the link into its server-address field also works). Pairing codes are
single-use and expire after five minutes, so generate a separate code per
client. Sessions currently last 30 days. Do not use `pair --remote`: that enables
an internet tunnel, which this deployment intentionally disables.

## Verify

```sh
systemctl status opencode
opencode service status
opencode api get /api/info
journalctl -u opencode -n 50
```

The service address should be `http://100.64.10.1:49374`. The HTTPS UI should load
on the tailnet, protected API requests without authentication should fail, and
requests forced through the VPS public IP should return 403. LAN/public access
to the backend must not work. Verify streaming responses and reconnecting from
Android after the initial pairing.
