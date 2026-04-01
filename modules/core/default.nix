{
  lib,
  pkgs,
  username,
  hostname,
  inputs,
  config,
  ...
}: {
  imports = [
    ./basic-cli.nix
    ./agenix.nix
    ./networking-variables.nix
    ./hjem.nix
  ];

  # Git
  programs.git = {
    enable = true;
    config = {
      user = {
        email = "github.login@cri.su";
        name = "${username}";
      };
      init.defaultBranch = "main";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Set up user llego
  users.users.${username} = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.initial-password.path;
    description = "Christian Sandberg";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  # Allow passwordless sudo for llego
  security.sudo.extraRules = [
    {
      users = ["${username}"];
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }
  ];

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = lib.mkDefault true;
    useDHCP = lib.mkDefault true;
  };

  # SSH server
  services.openssh.enable = true;

  # Tailscale
  services.tailscale = {
    enable = true;
  };

  # Beszel monitoring agent
  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environmentFile = "/var/lib/beszel-agent/env";
    environment = {
      PORT = "45876";
      DISABLE_SSH = "true";
      HUB_URL = config.networkVars.beszel.hubUrl;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Locale
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_COLLATE = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
    LC_MONETARY = "en_IE.UTF-8"; # Euro with period decimal separator
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "en_DK.UTF-8"; # Period for decimal separator
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "en_DK.UTF-8"; # ISO 8601 date format (YYYY-MM-DD)
  };
  console.keyMap = "sv-latin1";

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = true;
      trusted-users = ["root" "${username}" "@wheel"];
      # Add binary cache
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-substituters = ["https://nix-community.cachix.org"];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Required by nixd (LSP) when using flakes
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  # not another nix helper
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nixconfig";
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  environment.sessionVariables = {
    FLAKE = "/home/${username}/nixconfig"; # Needed by nh to work from any dir
  };

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 10;
}
