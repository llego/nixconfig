let
  # SSH host public keys
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILva2Z3+lvyJvKkOQ+0E6AwVYJxVsZD53VHajMMc01qi";
  crisuflix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgGmbiMVNWY5xjHb66kKSHRvUFTkjsp1/2h+5/6IK/z";
  christiansandberg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMen/Dv1097eSwB/8kx2vDGVrE1THvuHKNI4VN0LCgok";

  # User key for encryption/decryption
  userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJADwUps+xVBj5uHuO68oR3USlmXdSosizvCQlKyKJnu";

  # Key groups
  allHosts = [laptop crisuflix christiansandberg];
  allKeys = allHosts ++ [userKey];
in {
  # Shared across all hosts
  "secrets/initial-password.age".publicKeys = allKeys;

  # crisuflix-specific secrets
  "secrets/nut-password.age".publicKeys = [crisuflix userKey];
  "secrets/beszel-env.age".publicKeys = [crisuflix christiansandberg userKey];

  # crisuflix + christiansandberg secrets (shared DDNS token)
  "secrets/cloudflare-ddns-token.age".publicKeys = [crisuflix christiansandberg userKey];

  # christiansandberg authelia secrets
  "secrets/authelia-christiansandberg-fi-jwt.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-christiansandberg-fi-storage.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-christiansandberg-fi-session.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-christiansandberg-fi-smtp.age".publicKeys = [christiansandberg userKey];

  # cri.su authelia secrets (VPS)
  "secrets/authelia-cri.su-jwt.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-cri.su-storage.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-cri.su-session.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-cri.su-smtp.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-cri.su-oidc-hmac.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-cri.su-oidc-private-key.age".publicKeys = [christiansandberg userKey];
  "secrets/authelia-cri.su-openwebui-secret.age".publicKeys = [christiansandberg userKey];

  "secrets/gotify-admin-password.age".publicKeys = [christiansandberg userKey];
  "secrets/esphome-dashboard-env.age".publicKeys = [crisuflix userKey];
  "secrets/mosquitto-mqtt-user-password.age".publicKeys = [crisuflix userKey];

  # laptop + crisuflix secrets
  "secrets/ha-mcp-token.age".publicKeys = [laptop crisuflix userKey];
}
