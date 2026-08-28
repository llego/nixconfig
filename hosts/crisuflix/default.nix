{
  modulesPath,
  username,
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  net = config.networkVars;
in {
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    ./../../modules/core
    ./../../modules/cli
    ./beets.nix
    ./home-automation.nix
    ./glances.nix
    # ./../../modules/hermes
    ./homepage.nix
    ./opencloud.nix
    ./restic-backup.nix
    ./ups.nix
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

    # Other apps
    opencode
    # ollama-cpu
    atool
    nitch
    usbutils

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
      "vm.zfs.arc_max" = 8589934592; # 8GB ZFS ARC cap (25% of 32GB RAM)
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

  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/a0bbceb1-f3a4-482d-90b3-f9c029f5f151";
  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-uuid/83AD-3B37";

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
        recursive = true;
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

  # Subnet router for home + IoT VLANs
  services.tailscale = {
    authKeyFile = config.age.secrets.tailscale-preauth-crisuflix.path;
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--advertise-routes=192.168.1.0/24,192.168.3.0/24"
    ];
    extraSetFlags = [
      "--ssh"
    ];
  };

  # Docker
  virtualisation.docker.enable = true;

  # Docker restores containers with restart=unless-stopped as soon as dockerd
  # starts. Traefik binds 100.64.0.1:80/443 and traefik-kop publishes routes
  # over tailscale0, so wait until Tailscale has restored the tailnet address.
  systemd.services.docker = {
    after = ["tailscaled.service" "tailscaled-set.service"];
    wants = ["tailscaled.service" "tailscaled-set.service"];
    preStart = ''
      for _ in $(seq 1 120); do
        if [ "$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null)" = "100.64.0.1" ]; then
          exit 0
        fi
        sleep 1
      done

      echo "Timed out waiting for Tailscale IPv4 100.64.0.1"
      exit 1
    '';
  };

  # Ensure the traefik Docker networks exists before any containers start.
  # All stacks reference them as external: true, so they must pre-exist.
  systemd.services.docker-network-traefik = {
    description = "Create traefik Docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.lib.getExe (pkgs.writeShellScriptBin "docker-network-traefik" ''
        ${pkgs.docker}/bin/docker network inspect traefik-internal > /dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create --driver bridge traefik-internal


        ${pkgs.docker}/bin/docker network inspect traefik-public > /dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create --driver bridge traefik-public
      '');
    };
  };
  users.users.${username}.extraGroups = ["docker" "apps" "llego" "hermes"];

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

  # Beszel monitoring agent (crisuflix-specific settings)
  services.beszel.agent = {
    extraPath = [pkgs.nvtopPackages.intel];
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

  # NFS Server
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/veckjarvi/media 100.64.0.0/10(sec=sys,rw,anonuid=568,anongid=568,all_squash,crossmnt,no_subtree_check)
      /mnt/illby/docker 100.64.0.0/10(sec=sys,rw,anonuid=568,anongid=568,all_squash,crossmnt,no_subtree_check)
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
      allowedTCPPorts = [
        22 # SSH
        5201 # iperf3
        net.crisuflix.jellyfin.port # Jellyfin
        # 45876 # Beszel Agent (opened by services.beszel.agent.openFirewall)
      ];
      interfaces.tailscale0 = {
        allowedTCPPorts = [
          net.nfs.rpcbind.port # NFS rpcbind
          net.nfs.port # NFS
          net.nfs.mountd.port # NFS mountd
        ];
        allowedUDPPorts = [
          net.nfs.rpcbind.port # NFS rpcbind
          net.nfs.port # NFS
          net.nfs.mountd.port # NFS mountd
        ];
      };
    };
  };

  # Enable SMART monitoring for disk health
  services.smartd = {
    enable = true;
    autodetect = true;
  };
}
