# NixOS Configuration

Multi-host NixOS flake.

## Hosts

| Host        | Purpose               |
| ----------- | --------------------- |
| `laptop`    | Daily driver          |
| `vps`       | Public edge           |
| `crisuflix` | NAS and home services |
| `rpi5`      | Home Assistant kiosk  |

## Public And Tailnet Routing

Public `*.cri.su` services terminate at Traefik on `vps`. Docker containers on `crisuflix` can publish selected Traefik labels with traefik-kop into Redis on `vps`, over the Headscale-managed Tailscale network. The edge Traefik reads those Redis routes and proxies back to `crisuflix` over the tailnet. A separate Traefik container on `crisuflix` publishes `*.llego.me` services to tailnet users; DNS for `*.llego.me` is managed in Hetzner. Authelia protects selected public routes, while private services stay reachable only through Tailscale.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontFamily": "ui-sans-serif, system-ui, sans-serif", "primaryBorderColor": "#64748b", "lineColor": "#64748b"}}}%%
flowchart TB
  classDef public fill:#eff6ff,stroke:#2563eb,color:#172554,stroke-width:2px
  classDef auth fill:#fff7ed,stroke:#ea580c,color:#7c2d12,stroke-width:2px
  classDef data fill:#f5f3ff,stroke:#7c3aed,color:#2e1065,stroke-width:2px

  subgraph PublicVPS[vps]
    direction TB
    EdgeTraefik[Traefik<br/>public edge]
    Authelia[Authelia<br/>selected routes]
    Redis[(Redis<br/>Traefik dynamic config)]
  end

  subgraph PublicCrisuflix[crisuflix]
    direction TB
    Kop[traefik-kop<br/>kop.namespace=vps]
    PublicContainers[Public Docker containers<br/>Host *.cri.su]
    PublicLocalServices[Native/local services<br/>Home Assistant, Music Assistant]
  end

  PublicUsers[Public users] -->|HTTPS *.cri.su| Internet((Internet)) --> EdgeTraefik
  PublicContainers -->|Docker labels| Kop
  Kop -->|writes routes over Tailscale| Redis
  EdgeTraefik -->|reads Redis provider| Redis
  EdgeTraefik -->|optional middleware| Authelia
  EdgeTraefik -->|proxies over Tailscale| PublicContainers
  EdgeTraefik -->|static routes over Tailscale| PublicLocalServices

  class PublicUsers,Internet,EdgeTraefik,PublicContainers,PublicLocalServices,Kop public
  class Authelia auth
  class Redis data
```

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontFamily": "ui-sans-serif, system-ui, sans-serif", "primaryBorderColor": "#64748b", "lineColor": "#64748b"}}}%%
flowchart TB
  classDef tailnet fill:#ecfdf5,stroke:#059669,color:#064e3b,stroke-width:2px
  classDef dns fill:#f8fafc,stroke:#64748b,color:#334155,stroke-width:2px
  classDef control fill:#fefce8,stroke:#ca8a04,color:#713f12,stroke-width:2px

  subgraph TailnetVPS[vps]
    direction TB
    Headscale[Headscale<br/>control plane]
  end

  subgraph TailnetCrisuflix[crisuflix]
    direction TB
    LocalTraefik[Traefik container<br/>tailnet reverse proxy]
    InternalContainers[Tailnet-only Docker containers<br/>traefik.instance=internal<br/>Host *.llego.me]
    InternalLocalServices[Native/local services<br/>Home Assistant, ESPHome, Dockge]
  end

  TailnetUsers[Tailnet users] -->|resolve *.llego.me| HetznerDNS[Hetzner DNS<br/>*.llego.me]
  TailnetUsers -->|Tailscale| Tailnet[Tailscale tailnet<br/>Headscale-controlled]
  HetznerDNS --> Tailnet
  Headscale -. manages .-> Tailnet
  Tailnet -->|HTTPS *.llego.me| LocalTraefik
  Tailnet --> TailnetDNS[Tailnet hostnames<br/>*.tailnet.cri.su]
  LocalTraefik -->|Docker provider| InternalContainers
  LocalTraefik -->|file provider| InternalLocalServices

  class TailnetUsers,Tailnet,LocalTraefik,InternalContainers,InternalLocalServices,TailnetDNS tailnet
  class HetznerDNS dns
  class Headscale control
```

- Public `*.cri.su` routes are served by `vps` Traefik and may use Authelia middleware.
- Tailnet `*.llego.me` routes are served by the Traefik container on `crisuflix`.
- Docker services on `crisuflix` use local Traefik labels for `*.llego.me` or `kop.namespace=vps` labels for the Redis-backed `vps` Traefik path.
- Tailnet-only services avoid public routers and are reachable through Tailscale, including `*.llego.me` and `*.tailnet.cri.su` names.
- Headscale runs on `vps` and provides the control plane for the tailnet that links the hosts.

## Layout

| Path         | Purpose                     |
| ------------ | --------------------------- |
| `hosts/`     | Per-machine NixOS configs   |
| `modules/`   | Reusable NixOS modules      |
| `dots/`      | User config sources         |
| `pkgs/`      | Local packages              |
| `secrets/`   | agenix secrets              |
| `docs/`      | Long-form notes             |
| `HANDOFF.md` | Current state, next actions |

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix) and are encrypted to SSH host keys plus user keys from `secrets.nix`.

```bash
agenix -e secrets/initial-password.age
agenix -r
```

## Custom Packages

Packages in `pkgs/` are standalone flakes with `inputs.nixpkgs.follows = "nixpkgs"`.
