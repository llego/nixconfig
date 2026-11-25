# IPv6-only Home Network: Testing Checklist

## Goal and guardrails

Assess whether Home can run without IPv4 while IoT remains dual-stack. Keep Home dual-stack until the important devices, services, and recovery paths have been tested and the change is explicitly approved. The IPv6-only test Wi-Fi is `crona_ipv6_test`; return devices to Home if testing disrupts normal use.

The lab uses Control D DNS64 and isolated Jool NAT64 on `crisuflix`. UniFi currently blocks normally routed Home traffic to `64:ff9b::/96`; Home would need an explicit policy change and DNS64 before an IPv6-only migration. IoT normally routed NAT64 traffic remains blocked.

## Repeatable device test

- [ ] Connect the device to `crona_ipv6_test` and verify a lab IPv6 address and no usable native IPv4 path; disable mobile data or other fallback paths where practical.
- [ ] Test native IPv6 internet access and an IPv4-only destination through DNS64/NAT64; verify the actual address or path rather than relying only on a successful page load.
- [ ] Test normal applications and local workflows, including IPv4-literal use where relevant.
- [ ] Test with Tailscale or other VPNs enabled and disabled where applicable; record which paths were used.
- [ ] Record date, pass/fail, limitations, and fallback below; restore the device to Home if needed.

An IPv6 address alone does not prove IPv6-only compatibility. For local discovery, test both devices on the same lab network and separately in their intended final networks.

## Personal devices

- [ ] **Ona's computer:** browsing, everyday applications, video calls, local files, and any VPN.
- [ ] **Pixel 10:** browsing, messaging, app updates, photos/backups, important apps, Tailscale, and casting.
- [ ] **Pixel 7:** browsing, messaging, app updates, photos/backups, important apps, Tailscale, and casting.
- [ ] **gaming-win:** browser, launchers, downloads, multiplayer, local discovery, and IPv4-literal dependencies.
- [ ] **Home laptop:** test essential local workflows and applications with Tailscale up and down. DNS64/NAT64 to Winamp and DuckDuckGo passed with Tailscale up after the latest deployment.
- [ ] **Kobo:** move to IoT Wi-Fi as the planned IPv4 fallback; verify library sync, store, and any local workflows. Forum reports suggest it lacks IPv6 support; this has not been independently verified.
- [ ] **Work Windows laptop (`OM-PF5T9N48`):** use IoT Wi-Fi as the agreed fallback. It did not work on the lab and did work on IoT; the underlying cause is unconfirmed. No Home-device access is needed.
- [ ] Identify unnamed Home devices previously observed at `192.168.1.138`, `.167`, `.174`, `.214`, and `.244`; addresses and presence may have changed. Choose a test or fallback for each.

## Media and voice

Move devices one at a time and restore them if needed. Verify both same-network and intended cross-network discovery and control.

- [ ] **Android TV:** streaming apps, updates, Jellyfin, remote control, and casting.
- [ ] **Nest Audio:** test Music Assistant discovery and control, cross-network casting, and Tidal and AntennaPod playback. Symfonium casting passed with phone and speaker on the lab; Tidal and AntennaPod casting failed.
- [ ] **Yamaha AVR:** Music Assistant discovery, control, playback, and wake from standby.
- [ ] **Home Assistant Voice:** discovery, voice requests, and connectivity to Home Assistant.
- [ ] Test casting and control from an IPv6-only client to any devices intended to remain on IoT; note whether existing firewall rules and discovery mechanisms support it.

## Infrastructure and local services

- [ ] Identify the roles of **rpi3** and **rpizero**, their IPv4 dependencies, and a recovery method before moving them; test their required functions.
- [ ] **rpi5:** verify Home Assistant kiosk, DNS, and Tailscale on the lab; plan a restart test with a recovery path.
- [ ] Inventory `crisuflix` service bindings, DNS names, and Home/IoT NIC use before changing either interface.
- [ ] From a lab client, test NAS shares, Home Assistant, Music Assistant, Jellyfin, Docker-hosted services, SSH, and other important administration paths.
- [x] Test printing from the lab laptop to the IoT HP printer. After adding the lab network to UniFi's Gateway mDNS Proxy, the printer's `.local` name resolved and the user confirmed printing works.
- [ ] Test other desired lab-to-IoT workflows, including camera viewing and media control. IPv4 on IoT alone does not provide IPv6-only Home clients with access to IPv4-only IoT services.
- [ ] Confirm router and NAS management and recovery without relying solely on Jool or external DNS.

Do not remove IPv4 from `crisuflix`, change its NIC arrangement, or weaken IoT isolation as part of this checklist without a separate reviewed plan.

## Resilience and migration decision

- [ ] During an agreed maintenance window, test Jool recovery after a service restart and a `crisuflix` reboot; verify dependent services and client reconnection.
- [ ] Verify UniFi lab-network matching after ISP prefix renumbering when an opportunity arises.
- [ ] Assess DNS64, Jool, and internet outage behavior and confirm an independent management path.
- [ ] Review failed workflows; fix them, use an accepted IoT fallback, or retain dual-stack Home.
- [ ] Before any Home migration, plan and test a UniFi NAT64 allow for Home and provide Home clients with DNS64; preserve intended IoT restrictions.
- [ ] Agree on a rollback plan and maintenance window before making Home IPv6-only.

## Test results

Add dated entries with device, network, VPN state, test, observed result, and follow-up. Avoid recording secrets.

- 2026-11-25: Lab laptop with Tailscale up reached Winamp and DuckDuckGo over DNS64/NAT64 after deployment; both returned HTTP 200.
- 2026-11-25: Work laptop did not work on lab Wi-Fi but worked on IoT Wi-Fi; cause not established.
- 2026-11-25: Lab laptop printed successfully to the IoT HP printer after the lab network was added to UniFi's Gateway mDNS Proxy. The printer's `.local` name resolved over mDNS to its IPv6 and IPv4 addresses.
- 2026-11-25: With both phone and reset Nest Audio on the IPv6-only lab, Symfonium casting worked. Tidal produced a sound on the speaker but the song continued playing on the phone; retry and test both devices on Home as a baseline. VPN state was not recorded.
- 2026-11-25: User reported that AntennaPod casting also does not work. Failure details and VPN state were not recorded.
- 2026-11-25: With phone on the lab and Nest Audio on Home, the speaker appeared in the Cast list but selection failed in Symfonium and Tidal with Tailscale both on and off. Captured lab-to-speaker IPv6 connections to TCP 8009 succeeded but the speaker closed or reset them; the cause remains unconfirmed.
