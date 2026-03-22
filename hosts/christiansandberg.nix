{
  modulesPath,
  username,
  inputs,
  config,
  pkgs,
  ...
}: {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./../modules/core.nix
    ./../modules/basic-cli.nix

    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./christiansandberg-disk-config.nix
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      "default-address-pools" = [
        {
          base = "172.21.0.0/16";
          size = 24;
        }
      ];
    };
  };
  users.users.${username}.extraGroups = ["docker"];

  # Ensure the traefik Docker network exists with the correct subnet.
  # All stacks reference it as external: true, so it must pre-exist.
  systemd.services.docker-network-traefik = {
    description = "Create traefik Docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.lib.getExe (pkgs.writeShellScriptBin "docker-network-traefik" ''
        ${pkgs.docker}/bin/docker network inspect traefik > /dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create --driver bridge --subnet=172.21.0.0/24 --gateway=172.21.0.1 traefik
      '');
    };
  };

  # Beszel monitoring agent (Tailscale-only)
  services.beszel.agent = {
    enable = true;
    openFirewall = false;
    environmentFile = "/var/lib/beszel-agent/env";
    environment = {
      PORT = "45876";
      # Bind only to Tailscale interface
      HOST = "100.78.37.16"; # christiansandberg Tailscale IP
    };
  };

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

  # Authelia authentication server
  services.authelia.instances.christiansandberg = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets.authelia-jwt.path;
      storageEncryptionKeyFile = config.age.secrets.authelia-storage.path;
      sessionSecretFile = config.age.secrets.authelia-session.path;
    };
    settings = {
      theme = "auto";
      default_2fa_method = "totp";

      server = {
        address = "tcp://0.0.0.0:9091/";
      };

      log = {
        level = "info";
      };

      totp = {
        disable = false;
        issuer = "christiansandberg.fi";
        algorithm = "SHA1";
        digits = 6;
        period = 30;
        skew = 1;
        secret_size = 32;
      };

      webauthn = {
        disable = false;
      };

      authentication_backend = {
        password_reset = {
          disable = false;
        };
        file = {
          path = "/var/lib/authelia-christiansandberg/users_database.yml";
          watch = false;
          search = {
            email = false;
            case_insensitive = false;
          };
          password = {
            algorithm = "argon2";
            argon2 = {
              variant = "argon2id";
              iterations = 3;
              memory = 65536;
              parallelism = 4;
              key_length = 32;
              salt_length = 16;
            };
          };
        };
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "*.christiansandberg.fi";
            resources = ["^/api([/?].*)?$"];
            policy = "bypass";
          }
          {
            domain = "*.christiansandberg.fi";
            policy = "two_factor";
          }
        ];
      };

      session = {
        name = "authelia_session";
        same_site = "lax";
        inactivity = "5m";
        expiration = "1h";
        remember_me = "1M";
        cookies = [
          {
            name = "authelia_session_cookie_name";
            domain = "christiansandberg.fi";
            authelia_url = "https://auth.christiansandberg.fi";
            default_redirection_url = "https://christiansandberg.fi";
            same_site = "lax";
          }
        ];
      };

      storage = {
        local = {
          path = "/var/lib/authelia-christiansandberg/db.sqlite3";
        };
      };

      notifier = {
        disable_startup_check = true;
        smtp = {
          address = "smtp://smtp.protonmail.ch:587";
          username = "mail@christiansandberg.fi";
          sender = "Authelia <mail@christiansandberg.fi>";
          subject = "[Authelia] {title}";
        };
      };
    };
    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.authelia-smtp.path;
    };
  };

  # Uptime Kuma monitoring tool
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3001";
      HOST = "0.0.0.0";
    };
  };

  # Gotify push notification server
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_PORT = 8079;  # Port 8080 used by Traefik dashboard
      GOTIFY_SERVER_LISTENADDR = "0.0.0.0";
      GOTIFY_DATABASE_DIALECT = "sqlite3";
      GOTIFY_DATABASE_CONNECTION = "data/gotify.db";
      GOTIFY_DEFAULTUSER_NAME = "admin";
      # GOTIFY_DEFAULTUSER_PASS is loaded from environmentFile
      GOTIFY_UPLOADEDIMAGESDIR = "data/images";
      GOTIFY_PLUGINSDIR = "data/plugins";
    };
    environmentFiles = [ config.age.secrets.gotify-admin-password.path ];
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
    # Firewall configuration
    # - Allows Docker containers to reach native NixOS services
    # - Allows Tailscale access to services
    firewall = {
      enable = true;
      checkReversePath = false;  # Required for Docker→host communication
      
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP (Traefik)
        443   # HTTPS (Traefik)
        9091  # Authelia (native service)
      ];
      
      # Docker containers need explicit rules to reach host services
      extraCommands = ''
        # Allow Docker traefik network to reach host services
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 9091 -j nixos-fw-accept -m comment --comment "Authelia from Docker"
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 8079 -j nixos-fw-accept -m comment --comment "Gotify from Docker"
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 3001 -j nixos-fw-accept -m comment --comment "Uptime-kuma from Docker"
        iptables -w -I nixos-fw -p tcp -s 172.21.0.0/24 --dport 8000 -j nixos-fw-accept -m comment --comment "Ihatemoney from Docker"
        iptables -w -I nixos-fw -p tcp -s 100.64.0.0/10 --dport 6379 -j nixos-fw-accept -m comment --comment "Redis from Tailscale"
        ip6tables -w -I nixos-fw -p tcp -s fd7a:115c:a1e0::/48 --dport 6379 -j nixos-fw-accept -m comment --comment "Redis from Tailscale IPv6"
      '';
    };
  };
}
