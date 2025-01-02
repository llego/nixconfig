{
  pkgs,
  username,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    nautilus
    #nautilus-python
    gnome-text-editor
    wget
    curl
    htop
    pavucontrol
    gparted
    baobab
    xorg.xrandr
    screen
    jq
    dig
    tree
    ncdu
    system-config-printer
    alejandra
    nixd
    usbutils
  ];

  # Zsh
  programs.zsh.enable = true;

  # Firefox
  programs.firefox = {
    enable = true;
    policies = {
      DisablePocket = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      DisplayBookmarksToolbar = "always";
      SearchBar = "unified";
      # EXTENSIONS
      # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/7?page=2
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
        # Bitwarden Password Manager:
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        # floccus:
        "floccus@handmadeideas.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/floccus/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  # SSH server
  services.openssh.enable = true;

  # Nano settings
  programs.nano = {
    enable = true;
    nanorc = builtins.readFile ../assets/nix.nanorc;
  };

  # not another nix helper
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nixconfig";
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  # Gnome Terminal
  #programs.gnome-terminal.enable = true;

  # nautilus-open-any-terminal
  # https://github.com/Stunkymonkey/nautilus-open-any-terminal
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
  #environment = {
  #  sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
  #  pathsToLink = [
  #    "/share/nautilus-python/extensions"
  #  ];
  #};

  # Tailscale
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=${username}"];
  };

  # Mullvad VPN
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # This is required in order for Mullvad to work
  services.resolved.enable = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings.userland-proxy = false;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
