let
  # SSH host public keys
  laptop = "ssh-ed25519 AAAAC3Nza...PLACEHOLDER_GET_FROM_LAPTOP";  # TODO: Run on laptop: cat /etc/ssh/ssh_host_ed25519_key.pub
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
}
