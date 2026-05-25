# OpenCloud file sync + Collabora Online (WOPI) module for crisuflix
#
# Routing: Internet → VPS Traefik → Tailscale → crisuflix
#   cloud.cri.su  → OpenCloud  (127.0.0.1:9200)
#   office.cri.su → Collabora  (0.0.0.0:9980, restricted by firewall)
#
# Gotchas addressed:
#   1. CSP override required for Collabora iframe embedding
#   2. COLLABORATION_APP_PROOF_DISABLE=true needed for WOPI proof key issues
#   3. Collabora SSL must be disabled (terminated at Traefik)
#   4. Font bind mount required for Collabora to render fonts correctly
{
  config,
  pkgs,
  lib,
  ...
}: let
  net = config.networkVars;
  cloudDomain = "cloud.cri.su";
  officeDomain = "office.cri.su";
in {
  # ── Secrets ───────────────────────────────────────────────────────────────
  age.secrets.opencloud-env = {
    file = ../secrets/opencloud-env.age;
    owner = "opencloud";
    group = "opencloud";
  };

  # ── OpenCloud ─────────────────────────────────────────────────────────────
  services.opencloud = {
    enable = true;
    url = "https://${cloudDomain}";
    address = "127.0.0.1";
    port = net.crisuflix.opencloud.port;

    environment = {
      PROXY_TLS = "false"; # TLS terminated at Traefik
      OC_INSECURE = "true"; # Required when behind reverse proxy without internal TLS

      # Collabora / WOPI integration
      OC_ADD_RUN_SERVICES = "collaboration";
      COLLABORATION_APP_NAME = "Office";
      COLLABORATION_APP_PRODUCT = "Collabora";
      COLLABORATION_APP_ADDR = "http://127.0.0.1:${toString net.crisuflix.collabora.port}";
      COLLABORATION_APP_INSECURE = "true";
      COLLABORATION_WOPI_SRC = "https://${cloudDomain}";
      COLLABORATION_APP_PROOF_DISABLE = "true"; # Avoids WOPI proof key mismatches
    };

    environmentFile = config.age.secrets.opencloud-env.path;

    settings = {
      proxy = {
        # CSP override: every directive must be re-declared when overriding.
        # The default values come from OpenCloud's upstream compose files.
        # The critical addition here is `office.cri.su` in frame-src, which
        # allows Collabora to be embedded in the OpenCloud web UI.
        # The NixOS module writes this to /etc/opencloud/proxy.yaml which
        # OpenCloud reads automatically via OC_CONFIG_DIR.
        csp = {
          directives = {
            child-src = ["'self'"];
            connect-src = [
              "'self'"
              "blob:"
              "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
              "https://update.opencloud.eu/"
            ];
            default-src = ["'none'"];
            font-src = ["'self'"];
            frame-ancestors = ["'self'"];
            frame-src = [
              "'self'"
              "blob:"
              "https://embed.diagrams.net"
              "https://${officeDomain}" # Collabora embed — the critical gotcha
              "https://docs.opencloud.eu"
            ];
            img-src = [
              "'self'"
              "data:"
              "blob:"
              "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
              "https://tile.openstreetmap.org/"
            ];
            manifest-src = ["'self'"];
            media-src = ["'self'"];
            object-src = [
              "'self'"
              "blob:"
            ];
            script-src = [
              "'self'"
              "'unsafe-inline'"
            ];
            style-src = [
              "'self'"
              "'unsafe-inline'"
            ];
          };
        };
      };
    };
  };

  # ── Collabora Online ──────────────────────────────────────────────────────
  services.collabora-online = {
    enable = true;
    port = net.crisuflix.collabora.port;

    # WOPI host: OpenCloud is the only allowed storage backend.
    # aliasGroups sets the aliasgroup1 env var that coolwsd reads.
    aliasGroups = [
      {host = "https://${cloudDomain}";}
    ];

    settings = {
      # Disable Collabora's own TLS — Traefik terminates SSL
      ssl = {
        "@enable" = false;
        "@termination" = true;
      };

      # Allow WOPI requests from localhost (OpenCloud) and from Traefik
      # arriving via Tailscale. The firewall restricts public exposure.
      net.post_allow.host = [
        "127\\.0\\.0\\.1"
        "::1"
        # Tailscale range (VPS reaches crisuflix via Tailscale for office.cri.su)
        "100\\..*"
      ];

      # Logging: keep it modest in production
      logging = {
        "@level" = "warning";
        "@color" = false;
      };
    };
  };

  # ── Font bind mount ───────────────────────────────────────────────────────
  # Collabora needs fonts installed on the host (not just in its systemplate)
  # to render them. Without this, fonts load in the font list but don't display.
  fileSystems."/usr/share/fonts/collabora" = let
    fontDir = pkgs.symlinkJoin {
      name = "collabora-fonts";
      paths = with pkgs; [
        corefonts # Arial, Times New Roman, etc. — essential for Office compat
        nerd-fonts.departure-mono
      ];
    };
  in {
    device = "${fontDir}/share/fonts";
    fsType = "none";
    options = ["bind"];
  };

  # ── Firewall ─────────────────────────────────────────────────────────────
  # Collabora listens on all interfaces so Traefik on VPS can reach it via
  # Tailscale. The port is NOT opened to the LAN — only Tailscale traffic
  # (100.x.x.x) reaches crisuflix on this port.
  networking.firewall.extraInputRules = lib.mkAfter ''
    ip saddr 100.0.0.0/8 tcp dport ${toString net.crisuflix.collabora.port} accept comment "Collabora: Tailscale only"
  '';
}
