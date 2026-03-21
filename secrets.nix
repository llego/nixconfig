let
  # SSH host public keys
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILva2Z3+lvyJvKkOQ+0E6AwVYJxVsZD53VHajMMc01qi";
  crisuflix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgGmbiMVNWY5xjHb66kKSHRvUFTkjsp1/2h+5/6IK/z";
  christiansandberg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMen/Dv1097eSwB/8kx2vDGVrE1THvuHKNI4VN0LCgok";

  # User key for encryption/decryption
  userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJADwUps+xVBj5uHuO68oR3USlmXdSosizvCQlKyKJnu";

  # Key groups
  allHosts = [ laptop crisuflix christiansandberg ];
  allKeys = allHosts ++ [ userKey ];
in
{
  # Shared across all hosts
  "secrets/initial-password.age".publicKeys = allKeys;

  # crisuflix-specific secrets
  "secrets/nut-password.age".publicKeys = [ crisuflix userKey ];
  "secrets/beszel-env.age".publicKeys = [ crisuflix userKey ];
  "secrets/cloudflare-ddns-token.age".publicKeys = [ crisuflix userKey ];
  "secrets/esphome-dashboard-env.age".publicKeys = [ crisuflix userKey ];
  "secrets/mosquitto-mqtt-user-password.age".publicKeys = [ crisuflix userKey ];

  # laptop + crisuflix secrets
  "secrets/ha-mcp-token.age".publicKeys = [ laptop crisuflix userKey ];
}
