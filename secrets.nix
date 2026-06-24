let
  # SSH host public keys
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILva2Z3+lvyJvKkOQ+0E6AwVYJxVsZD53VHajMMc01qi";
  crisuflix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgGmbiMVNWY5xjHb66kKSHRvUFTkjsp1/2h+5/6IK/z";
  vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMen/Dv1097eSwB/8kx2vDGVrE1THvuHKNI4VN0LCgok";
  rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8tEPMZr64GQEKQcVrEP9wojWAqmlCWUVqiH0oG1yAF";

  # User key for encryption/decryption
  userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJADwUps+xVBj5uHuO68oR3USlmXdSosizvCQlKyKJnu";

  # Key groups
  allHosts = [laptop crisuflix vps rpi5];
  allKeys = allHosts ++ [userKey];
in {
  # Shared across all hosts
  "secrets/beszel-env.age".publicKeys = allKeys;
  "secrets/ha-mcp-token.age".publicKeys = allKeys;
  "secrets/bandcamp-cookie.age".publicKeys = allKeys;
  "secrets/supermemory-api-key.age".publicKeys = [laptop crisuflix userKey];

  # crisuflix-specific secrets
  "secrets/hermes-env.age".publicKeys = [crisuflix userKey];
  "secrets/yle-sonarr-import-env.age".publicKeys = [crisuflix userKey];
  "secrets/nut-password.age".publicKeys = [crisuflix userKey];
  "secrets/tailscale-preauth-crisuflix.age".publicKeys = [crisuflix userKey];

  # laptop-specific secrets
  "secrets/tailscale-preauth-laptop.age".publicKeys = [laptop userKey];

  # rpi5-specific secrets
  "secrets/tailscale-preauth-rpi5.age".publicKeys = [rpi5 userKey];

  # Hetzner DNS API token (VPS Traefik DNS-01 + DDNS)
  "secrets/hetzner-dns-token.age".publicKeys = [vps userKey];

  # vps-specific secrets
  "secrets/tailscale-preauth-vps.age".publicKeys = [vps userKey];

  # deSEC DNS API token (VPS Traefik DNS-01 for csandberg.consulting)
  "secrets/desec-dns-token.age".publicKeys = [vps userKey];

  # cri.su authelia secrets (VPS)
  "secrets/authelia-cri.su-jwt.age".publicKeys = [vps userKey];
  "secrets/authelia-cri.su-storage.age".publicKeys = [vps userKey];
  "secrets/authelia-cri.su-session.age".publicKeys = [vps userKey];
  "secrets/authelia-cri.su-smtp.age".publicKeys = [vps userKey];
  "secrets/authelia-cri.su-oidc-hmac.age".publicKeys = [vps userKey];
  "secrets/authelia-cri.su-oidc-private-key.age".publicKeys = [vps userKey];
  "secrets/authelia-cri.su-openwebui-secret.age".publicKeys = [vps userKey];

  "secrets/gotify-admin-password.age".publicKeys = [vps userKey];
  "secrets/esphome-dashboard-env.age".publicKeys = [crisuflix userKey];
  "secrets/mosquitto-mqtt-user-password.age".publicKeys = [crisuflix userKey];
  "secrets/frigate-env.age".publicKeys = [crisuflix userKey];
  "secrets/restic-hetzner-password.age".publicKeys = [crisuflix userKey];
  "secrets/hetzner-s3-credentials.age".publicKeys = [crisuflix userKey];

  # OpenCloud admin password and WOPI env vars
  "secrets/opencloud-env.age".publicKeys = [crisuflix userKey];

  # Homepage dashboard - Unifi widget credentials
  "secrets/homepage-unifi-password.age".publicKeys = [crisuflix userKey];

  # Homepage dashboard - Gotify widget client token
  "secrets/homepage-gotify-key.age".publicKeys = [crisuflix userKey];

  # Headplane cookie secret and Headscale API key (VPS)
  "secrets/headplane-cookie-secret.age".publicKeys = [vps userKey];
  "secrets/headscale-api-key.age".publicKeys = [vps userKey];
  "secrets/headscale-oidc-client-secret.age".publicKeys = [vps userKey];
}
