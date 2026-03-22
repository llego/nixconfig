{
  modulesPath,
  username,
  inputs,
  config,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./../modules/core.nix
    ./../modules/basic-cli.nix
    ./../modules/secrets.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./christiansandberg-disk-config.nix
  ];

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = ["docker"];

  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=${username}"];
  };

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 10;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # Cloudflare DDNS for christiansandberg.fi domain
  services.cloudflare-ddns = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-ddns-token.path;
    domains = [
      "christiansandberg.fi"
    ];
    proxied = "false";
  };

  networking = {
    useDHCP = true;
    networkmanager.enable = false;
    interfaces.enp1s0.ipv6.addresses = [
      {
        address = "2a01:4f9:c010:803e::1";
        prefixLength = 64;
      }
    ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443];
      extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport 6379 accept comment "Redis for traefik-kop from Tailscale"
        ip6 saddr fd7a:115c:a1e0::/48 tcp dport 6379 accept comment "Redis for traefik-kop from Tailscale IPv6"
      '';
    };
  };
}
