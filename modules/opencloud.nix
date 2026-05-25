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
    address = net.hosts.crisuflix; # must be reachable from VPS Traefik via Tailscale
    port = net.crisuflix.opencloud.port;
    stateDir = "/mnt/illby/appstorage/opencloud";

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

      # External OIDC — Authelia as identity provider
      OC_OIDC_ISSUER = "https://auth.cri.su";
      OC_EXCLUDE_RUN_SERVICES = "idp"; # disable built-in IDP; Authelia handles auth
      PROXY_OIDC_REWRITE_WELLKNOWN = "true"; # expose .well-known/openid-configuration via cloud.cri.su
      PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none"; # Authelia issues opaque (non-JWT) access tokens
      PROXY_AUTOPROVISION_ACCOUNTS = "true"; # create OpenCloud user on first Authelia login
      PROXY_ROLE_ASSIGNMENT_DRIVER = "default"; # all auto-provisioned users get 'user' role
      PROXY_USER_OIDC_CLAIM = "preferred_username"; # match Authelia username → OpenCloud username
      PROXY_USER_CS3_CLAIM = "username";
      GRAPH_USERNAME_MATCH = "none"; # allow any username characters
      WEB_OIDC_SCOPE = "openid profile email groups";
    };

    environmentFile = config.age.secrets.opencloud-env.path;

    settings = {
      proxy = {
        # Point the proxy service at the CSP config file.
        # The csp key cannot be inlined in proxy.yaml — OpenCloud's proxy service
        # reads CSP from a separate file referenced by csp_config_file_location.
        csp_config_file_location = "/etc/opencloud/csp.yaml";
      };
    };
  };

  # ── CSP config file ───────────────────────────────────────────────────────
  # The proxy service reads CSP from a separate YAML file (csp_config_file_location).
  # Inlining `csp:` under settings.proxy does not work — the key is unknown to the
  # proxy YAML schema. This file is the correct mechanism.
  # All directives must be fully declared; there is no merge with defaults.
  environment.etc."opencloud/csp.yaml".text = ''
    directives:
      child-src:
        - "'self'"
      connect-src:
        - "'self'"
        - "blob:"
        - "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
        - "https://update.opencloud.eu/"
      default-src:
        - "'none'"
      font-src:
        - "'self'"
      frame-ancestors:
        - "'self'"
      frame-src:
        - "'self'"
        - "blob:"
        - "https://embed.diagrams.net"
        - "https://${officeDomain}"
        - "https://docs.opencloud.eu"
      img-src:
        - "'self'"
        - "data:"
        - "blob:"
        - "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"
        - "https://tile.openstreetmap.org/"
      manifest-src:
        - "'self'"
      media-src:
        - "'self'"
      object-src:
        - "'self'"
        - "blob:"
      script-src:
        - "'self'"
        - "'unsafe-inline'"
      style-src:
        - "'self'"
        - "'unsafe-inline'"
  '';

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
      # Public hostname Collabora advertises in WOPI discovery XML.
      # Without this it advertises https://127.0.0.1:9980 and browsers can't connect.
      server_name = "${officeDomain}:443";

      # Disable Collabora's own TLS — Traefik terminates SSL.
      # Must set child elements (ssl.enable, ssl.termination), NOT XML attributes
      # (@enable/@termination) — Collabora reads the child elements, not the attributes.
      ssl.enable = false;
      ssl.termination = true;

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
