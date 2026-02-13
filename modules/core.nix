{
  lib,
  pkgs,
  username,
  hostname,
  inputs,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    htop
    screen
    zsh
    oh-my-posh
    fzf
  ];

  # Zsh
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    enableGlobalCompInit = true;
  };

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
    initialPassword = "12345";
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

  # Nano settings
  programs.nano = {
    enable = true;
    nanorc = builtins.readFile ./nix.nanorc;
  };

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  # SSH server
  services.openssh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Locale
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
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
