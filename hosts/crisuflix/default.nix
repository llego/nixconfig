{
  modulesPath,
  username,
  inputs,
  pkgs,
  config,
  lib,
  ...
}: {
  system.stateVersion = "24.05";

  # users.users.root.openssh.authorizedKeys.keys = [
  #   # change this to your ssh key
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcYhLnYhEmrmWViN9z9VgEQPInZ/WxSCAgDV5rj4lpj mail@christiansandberg.fi"
  # ];

  imports = [
    inputs.disko.nixosModules.disko
    ./../../modules/core.nix
    ./../../modules/basic-cli.nix
    ./../../modules/home-automation.nix
    ./../../modules/ai.nix
    ./../../modules/frigate.nix
    # ./../modules/storj-backup.nix
    ./disk-config.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  environment.systemPackages = with pkgs; [
    # Packages useful for NAS management
    zfs
    iotop
    smartmontools
    lm_sensors
    nfs-utils

    # Nix stuff
    nixd
    alejandra
  ];

  # Hardware configuration
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Boot configuration
  boot = {
    # Boot loader
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    # Hardware-specific kernel modules
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "sd_mod"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];

    # Kernel settings
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288; # For media servers, file sync, dev tools
      "fs.inotify.max_user_instances" = 512; # For multiple Docker containers
    };

    # Filesystem support
    supportedFilesystems = ["zfs"];

    # aarch64 build support via QEMU user-mode emulation
    binfmt.emulatedSystems = ["aarch64-linux"];

    # ZFS configuration
    zfs = {
      forceImportRoot = false;
      extraPools = ["illby" "veckjarvi"]; # Import existing pools from TrueNAS
    };
  };

  # aarch64 build support
  nix.settings.extra-platforms = ["aarch64-linux"];

  # Required for ZFS - from existing TrueNAS
  networking.hostId = "447b046a";

  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      pools = ["illby" "veckjarvi"];
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # Use sanoid for flexible snapshot management
  services.sanoid = {
    enable = true;

    templates.default = {
      frequently = 4; # 15-min intervals
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
      autosnap = true;
      autoprune = true;
    };

    datasets = {
      "illby" = {
        useTemplate = ["default"];
        recursive = true;
      };
      "illby/transient" = {
        autosnap = false;
        autoprune = false;
      };
      "veckjarvi" = {
        useTemplate = ["default"];
        recursive = true;
      };
      "veckjarvi/frigate-storage" = {
        autosnap = false;
        autoprune = false;
      };
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Ensure the traefik Docker network exists before any containers start.
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
          ${pkgs.docker}/bin/docker network create --driver bridge traefik
      '');
    };
  };
  users.users.${username}.extraGroups = ["docker" "apps" "llego"];

  # Apps user for Docker containers (UID/GID 568)
  users.groups.apps = {
    gid = 568;
  };

  users.users.apps = {
    isSystemUser = true;
    uid = 568;
    group = "apps";
    description = "Apps user for Docker containers";
  };

  # Beszel monitoring agent
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environmentFile = "/var/lib/beszel-agent/env";
    environment = {
      PORT = "45876";
    };
    extraPath = [pkgs.nvtopPackages.intel];

    # Enable SMART monitoring
    smartmon = {
      enable = true;
      deviceAllow = [
        "/dev/sda"
        "/dev/sdb"
        "/dev/sdc"
        "/dev/sdd"
        "/dev/sde"
        "/dev/sdf"
        "/dev/sdg"
        "/dev/sdh"
        "/dev/nvme0"
        "/dev/nvme1"
        "/dev/nvme2"
      ];
    };
  };

  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=${username}"];
  };

  # NFS Server
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/veckjarvi/media/filmer 192.168.1.0/24(sec=sys,rw,anonuid=568,anongid=568,all_squash,no_subtree_check)
      /mnt/veckjarvi/media/tv 192.168.1.0/24(sec=sys,rw,anonuid=568,anongid=568,all_squash,no_subtree_check)
      /mnt/veckjarvi/backups/haos-backup 192.168.1.0/24(sec=sys,rw,anonuid=3001,all_squash,no_subtree_check)
      /mnt/illby/docker/data 192.168.1.214(sec=sys,rw,anonuid=0,all_squash,no_subtree_check)
      /mnt/illby/docker/stacks 192.168.1.214(sec=sys,rw,anonuid=0,anongid=0,all_squash,no_subtree_check)
    '';
  };

  # OpenSSH with hardening
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # Cloudflare DDNS (native service, migrated from Docker)
  services.cloudflare-ddns = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-ddns-token.path;
    domains = [
      "csandberg.fi"
    ];
    proxied = "false";
  };

  # Network bridges (matching TrueNAS setup)
  networking = {
    useDHCP = false;
    networkmanager.enable = false;

    bridges = {
      br0 = {
        interfaces = ["enp5s0"];
      };
      br1 = {
        interfaces = ["enp6s0"];
      };
    };

    interfaces = {
      br0.ipv4.addresses = [
        {
          address = "192.168.1.101";
          prefixLength = 24;
        }
        {
          address = "192.168.1.103";
          prefixLength = 24;
        }
      ];
      br1.ipv4.addresses = [
        {
          address = "192.168.3.103";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };

    nameservers = ["192.168.1.1"];

    # Firewall
    firewall = {
      enable = true;
      # Allow Yamaha MusicCast to send UDP push events (position updates, state changes)
      # back to Music Assistant on its ephemeral UDP port. The Yamaha sends these as
      # unsolicited packets which are otherwise blocked by the stateful firewall.
      extraInputRules = ''
        ip saddr 192.168.1.247 udp accept comment "Yamaha MusicCast UDP events to Music Assistant"
      '';
      allowedTCPPorts = [
        22 # SSH
        111 # NFS rpcbind
        2049 # NFS
        3493 # NUT (UPS monitoring)
        8095 # Music Assistant (Web UI)
        8096 # Jellyfin
        8098 # Music Assistant (Stream Server)
        8123 # Home Assistant
        1883 # MQTT (Mosquitto)
        20048 # NFS mountd
        # 45876 # Beszel Agent (opened by services.beszel.agent.openFirewall)
      ];
      allowedUDPPorts = [
        111 # NFS rpcbind
        2049 # NFS
        5353 # mDNS (Chromecast discovery)
        20048 # NFS mountd
      ];
    };
  };

  # Enable SMART monitoring for disk health
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # UPS Configuration (NUT - Network UPS Tools)
  power.ups = {
    enable = true;
    mode = "standalone";

    ups."ups" = {
      driver = "usbhid-ups";
      port = "auto";
    };

    upsmon = {
      monitor."ups" = {
        user = "upsmon";
        powerValue = 1;
        system = "ups@localhost";
      };

      settings = {
        # Shutdown configuration
        FINALDELAY = 5; # Wait 5 seconds before actual shutdown

        # Notifications
        NOTIFYFLAG = [
          ["ONLINE" "SYSLOG+WALL"]
          ["ONBATT" "SYSLOG+WALL"]
          ["LOWBATT" "SYSLOG+WALL+EXEC"] # Log, wall, and execute shutdown on low battery
          ["FSD" "SYSLOG+WALL+EXEC"] # Forced shutdown signal
          ["SHUTDOWN" "SYSLOG+WALL"]
          ["REPLBATT" "SYSLOG+WALL"]
        ];
      };
    };

    users = {
      upsmon = {
        passwordFile = "/run/keys/nut-password";
        upsmon = "primary";
      };
    };
  };
}
