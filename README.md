# NixOS Configuration

This is my (perhaps overly complex) nixconfig which covers basically all of my machines. Most of the configuration is AI generated.

My Docker Compose files are not available in this repo.

## Hosts

| Host        | Purpose               |
| ----------- | --------------------- |
| `laptop`    | Daily driver          |
| `vps`       | Public edge           |
| `crisuflix` | NAS and home services |
| `rpi5`      | Home Assistant kiosk  |

Notable pieces of software in my infrastructure that bring me joy (some of these are running as Docker containers and therefore not configured in this repo):

- **NixOS:** [hjem](https://github.com/feel-co/hjem), [hjem-impure](https://github.com/Rexcrazy804/hjem-impure), [disko](https://github.com/nix-community/disko), [agenix](https://github.com/ryantm/agenix), [mcp-nixos](https://github.com/utensils/mcp-nixos)
- **Storage:** [ZFS](https://openzfs.org/), [Sanoid](https://github.com/jimsalterjrs/sanoid), [Restic](https://restic.net/)
- **Media management:** [Jellyfin](https://jellyfin.org/), [SABnzbd](https://sabnzbd.org/), [Servarr](https://wiki.servarr.com/), [Grimmory](https://github.com/gabe565/grimmory), [Immich](https://immich.app/), [Beets](https://beets.io/)
- **Networks:** [Traefik](https://traefik.io/), [traefik-kop](https://github.com/jittering/traefik-kop), [Pocket ID](https://pocket-id.org/), [Tailscale](https://tailscale.com/), [Headscale](https://headscale.net/), [Headplane](https://github.com/tale/headplane)
- **Admin and monitoring:** [Dockge](https://dockge.kuma.pet/), [Gotify](https://gotify.net/), [Homepage](https://gethomepage.dev/), [Uptime Kuma](https://uptime.kuma.pet/), [Beszel](https://beszel.dev/)
- **Desktop environment:** [Niri](https://github.com/YaLTeR/niri), [Noctalia](https://github.com/noctalia-dev/noctalia), [Helix](https://helix-editor.com/), [Yazi](https://yazi-rs.github.io/), [Foot](https://codeberg.org/dnkl/foot), [Zen Browser](https://zen-browser.app/), [OpenCode](https://opencode.ai/)
- **Home automation:** [Home Assistant](https://www.home-assistant.io/), [Music Assistant](https://music-assistant.io/), [Frigate](https://frigate.video/)
- **Tools:** [OpenCloud](https://opencloud.eu/), [Anchor Notes](https://github.com/ZhFahim/anchor), [I Hate Money](https://ihatemoney.org/), [SparkyFitness](https://github.com/CodeWithCJ/SparkyFitness)

## Public And Tailnet Routing

Traefik on `vps` serves public `*.cri.su` services and tailnet-only `*.vpn.cri.su` services. Docker services on `crisuflix` publish routes through traefik-kop and Redis, with backend traffic carried over Tailscale. Headscale manages the tailnet and private DNS; Pocket ID provides application OIDC sign-in where configured.

### Public users accessing \*.cri.su

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontFamily": "ui-sans-serif, system-ui, sans-serif", "primaryBorderColor": "#64748b", "lineColor": "#64748b"}}}%%
flowchart TB
  classDef public fill:#eff6ff,stroke:#2563eb,color:#172554,stroke-width:2px
  classDef dns fill:#f8fafc,stroke:#64748b,color:#334155,stroke-width:2px
  classDef auth fill:#fff7ed,stroke:#ea580c,color:#7c2d12,stroke-width:2px
  classDef data fill:#f5f3ff,stroke:#7c3aed,color:#2e1065,stroke-width:2px

  subgraph PublicVPS["☁️ <strong>vps</strong> - public edge"]
    direction TB
    EdgeTraefik["🚦 Traefik <br/> public reverse proxy"]
    PocketID["🔐 Pocket ID<br/>OIDC"]
    Redis[("🗄️ Redis<br/>Traefik dynamic config")]
  end

  subgraph PublicCrisuflix["🏠 <strong>crisuflix</strong> - home server"]
    direction TB
    Kop["🔁 traefik-kop<br/>kop.namespace=vps"]
    PublicContainers["📦 Public Docker containers"]
    PublicLocalServices["🧩 Host services<br/>static Traefik routes"]
  end


  PublicUsers["🧑<br/>Public users"] -->|resolve *.cri.su| HetznerDNS["🌐 Hetzner DNS<br/>*.cri.su --> vps public IP"] --> EdgeTraefik
  PublicContainers -->|labels: <code>kop.namespace=vps</code> + <code>traefik.enable=true</code>| Kop
  Kop -->|traefik-kop writes routes to redis| Redis
  EdgeTraefik -->|traefik reads redis provider| Redis
  PublicContainers -.->|application OIDC sign-in, where configured| PocketID
  EdgeTraefik -->|vps traefik proxies to Docker containers on crisuflix| PublicContainers
  EdgeTraefik -->|vps traefik proxies to systemd services on crisuflix| PublicLocalServices

  click Kop "https://github.com/jittering/traefik-kop" "Follow link"

  class PublicUsers,EdgeTraefik,PublicContainers,PublicLocalServices,Kop public
  class HetznerDNS dns
  class PocketID auth
  class Redis data
```

### Tailnet users accessing \*.vpn.cri.su

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontFamily": "ui-sans-serif, system-ui, sans-serif", "primaryBorderColor": "#64748b", "lineColor": "#64748b"}}}%%
flowchart TB
  classDef tailnet fill:#ecfdf5,stroke:#059669,color:#064e3b,stroke-width:2px
  classDef dns fill:#f8fafc,stroke:#64748b,color:#334155,stroke-width:2px
  classDef control fill:#fefce8,stroke:#ca8a04,color:#713f12,stroke-width:2px
  classDef data fill:#f5f3ff,stroke:#7c3aed,color:#2e1065,stroke-width:2px

  subgraph TailnetVPS["☁️ <strong>vps</strong>"]
    direction TB
    Headscale["🧭 Headscale<br/>control plane"]
    Dnsmasq["📛 dnsmasq<br/>*.vpn.cri.su --> 100.64.0.4"]
    EdgeTraefik["🚦 Traefik<br/>edge reverse proxy"]
    Redis[("🗄️ Redis<br/>Traefik dynamic config")]
  end

  subgraph TailnetCrisuflix["🏠 <strong>crisuflix</strong> - home server"]
    direction TB
    Kop["🔁 traefik-kop<br/>kop.namespace=vps"]
    PrivateContainers["🔒📦 Private Docker containers<br/>Host(service.vpn.cri.su)"]
  end

  TailnetUsers["🧑<br/>Tailnet users"] -->|Headscale split DNS for vpn.cri.su| Dnsmasq
  Dnsmasq -->|100.64.0.4| Tailnet["🕸️ Tailscale tailnet"]
  Headscale -. manages DNS and nodes .-> Tailnet
  Tailnet --> EdgeTraefik
  PrivateContainers -->|labels: <code>kop.namespace=vps</code> + private Host rule| Kop
  Kop -->|traefik-kop writes routes to redis| Redis
  EdgeTraefik -->|traefik reads redis provider| Redis
  EdgeTraefik -->|tailnet guard + optional per-router middleware; published backend ports| PrivateContainers

  click Kop "https://github.com/jittering/traefik-kop" "Follow link"

  class TailnetUsers,Tailnet,Dnsmasq,EdgeTraefik,PrivateContainers,Kop tailnet
  class Headscale control
  class Redis data
```

## Layout

| Path         | Purpose                     |
| ------------ | --------------------------- |
| `hosts/`     | Per-machine NixOS configs   |
| `modules/`   | Reusable NixOS modules      |
| `dots/`      | Userspace dotfiles          |
| `pkgs/`      | Custom packages             |
| `secrets/`   | agenix secrets              |
| `docs/`      | Long-form notes             |
| `HANDOFF.md` | Current state, next actions |

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix) and are encrypted to SSH host keys plus user keys from `secrets.nix`.

```bash
agenix -e secrets/initial-password.age
agenix -r
```

## Nixpkgs Policy

`nixpkgs` follows `nixos-unstable` by default. Use `pkgs-stable` for explicit stable package or service overrides. `rpi5` is the exception: it is built from `nixpkgs-stable` for safer remote Raspberry Pi updates.

## Custom Packages

Packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.

`pkgs/album-downloader` exposes both the cheap `album-downloader` shell wrapper and the expensive `bandsnatch` Rust package. `bandsnatch` keeps its own pinned dependency graph so root `nixpkgs` updates do not churn its store path. If that package flake changes, prime `llego.cachix.org` from inside the package flake before rebuilding clean hosts:

```bash
cd pkgs/album-downloader
nix build .#bandsnatch
cachix push llego ./result
```
