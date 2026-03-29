let
  # SSH host public keys
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILva2Z3+lvyJvKkOQ+0E6AwVYJxVsZD53VHajMMc01qi";
  crisuflix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgGmbiMVNWY5xjHb66kKSHRvUFTkjsp1/2h+5/6IK/z";
  vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMen/Dv1097eSwB/8kx2vDGVrE1THvuHKNI4VN0LCgok";
  rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZmcWOngy7+BeiPaqtIA82u+KardO6gZEh8B9RXhrc4";

  # User key for encryption/decryption
  userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJADwUps+xVBj5uHuO68oR3USlmXdSosizvCQlKyKJnu";

  # Key groups
  allHosts = [laptop crisuflix vps rpi5];
  allKeys = allHosts ++ [userKey];
in {
  # Shared across all hosts
  "secrets/initial-password.age".publicKeys = allKeys;
  "secrets/beszel-env.age".publicKeys = allKeys;
  "secrets/ha-mcp-token.age".publicKeys = [userKey];

  # crisuflix-specific secrets
  "secrets/nut-password.age".publicKeys = [crisuflix userKey];

  # crisuflix + vps secrets (shared DDNS token)
  "secrets/cloudflare-ddns-token.age".publicKeys = [crisuflix vps userKey];

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
}
