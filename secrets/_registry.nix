let
  keys = rec {
    # SSH host public keys
    laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILva2Z3+lvyJvKkOQ+0E6AwVYJxVsZD53VHajMMc01qi";
    crisuflix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgGmbiMVNWY5xjHb66kKSHRvUFTkjsp1/2h+5/6IK/z";
    vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMen/Dv1097eSwB/8kx2vDGVrE1THvuHKNI4VN0LCgok";
    rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8tEPMZr64GQEKQcVrEP9wojWAqmlCWUVqiH0oG1yAF";

    # User key for encryption/decryption
    user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJADwUps+xVBj5uHuO68oR3USlmXdSosizvCQlKyKJnu";

    allHosts = [laptop crisuflix vps rpi5];
    all = allHosts ++ [user];
  };
in {
  inherit keys;

  secrets = with keys; {
    beszel-env = {
      publicKeys = all;
      hosts = ["laptop" "crisuflix" "vps" "rpi5"];
      path = "/var/lib/beszel-agent/env";
      mode = "0640";
      owner = "root";
      group = "beszel-agent";
    };

    ha-mcp-token = {
      publicKeys = all;
      hosts = ["laptop" "crisuflix"];
      mode = "0400";
      owner = "llego";
      group = "users";
    };

    bandcamp-cookie = {
      publicKeys = all;
      hosts = ["laptop" "crisuflix" "vps" "rpi5"];
      mode = "0400";
      owner = "llego";
      group = "users";
    };

    nut-password = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      path = "/run/keys/nut-password";
      mode = "0400";
      owner = "root";
      group = "root";
    };

    tailscale-preauth-crisuflix = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    tailscale-preauth-laptop = {
      publicKeys = [laptop user];
      hosts = ["laptop"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    gotify-desktop-token = {
      publicKeys = [laptop user];
      hosts = ["laptop"];
      mode = "0400";
      owner = "llego";
      group = "users";
    };

    tailscale-preauth-rpi5 = {
      publicKeys = [rpi5 user];
      hosts = ["rpi5"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    hetzner-dns-token = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0440";
      owner = "root";
      group = "hetzner-ddns";
    };

    hetzner-dns-token-env-variable = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    tailscale-preauth-vps = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    desec-dns-token = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    "authelia-cri.su-jwt" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    "authelia-cri.su-storage" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    "authelia-cri.su-session" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    "authelia-cri.su-smtp" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    "authelia-cri.su-oidc-hmac" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    "authelia-cri.su-oidc-private-key" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    "authelia-cri.su-openwebui-secret" = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "authelia-cri.su";
      group = "authelia-cri.su";
    };

    gotify-admin-password = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    traefik-redis-password = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    traefik-redis-env-vps = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    esphome-dashboard-env = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    mosquitto-mqtt-user-password = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      mode = "0400";
      owner = "mosquitto";
      group = "mosquitto";
    };

    restic-storj-password = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    storj-s3-credentials = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      path = "/var/lib/restic/storj-s3-credentials";
      mode = "0400";
      owner = "root";
      group = "root";
    };

    restic-hetzner-password = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    hetzner-s3-credentials = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      path = "/var/lib/restic/hetzner-s3-credentials";
      mode = "0400";
      owner = "root";
      group = "root";
    };

    opencloud-env = {
      publicKeys = [crisuflix user];
      hosts = ["crisuflix"];
      owner = "opencloud";
      group = "opencloud";
    };

    homepage-unifi-password = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    homepage-gotify-key = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "root";
      group = "root";
    };

    headplane-cookie-secret = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "headscale";
      group = "headscale";
    };

    headscale-api-key = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "headscale";
      group = "headscale";
    };

    headscale-oidc-client-secret = {
      publicKeys = [vps user];
      hosts = ["vps"];
      mode = "0400";
      owner = "headscale";
      group = "headscale";
    };
  };
}
