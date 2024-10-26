{
  pkgs,
  inputs,
  username,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs; [
    firefox
    nautilus
    gnome-text-editor
    wget
    curl
    htop
    pavucontrol
    gparted
    baobab
    nixd
    alejandra
  ];

  # Required by nixd (LSP) when using flakes
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  # Zsh
  programs.zsh.enable = true;

  # Nano settings
  programs.nano = {
    enable = true;
    nanorc = builtins.readFile ./home-manager/assets/nix.nanorc;
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
