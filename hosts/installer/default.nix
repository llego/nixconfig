{
  inputs,
  pkgs,
  ...
}: let
  # Pre-populated known_hosts so SSH to crisuflix never prompts during install.
  # Obtained with: ssh-keyscan crisuflix.home
  crisuflixKnownHosts = ''
    crisuflix.home ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgGmbiMVNWY5xjHb66kKSHRvUFTkjsp1/2h+5/6IK/z
  '';
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../modules/wifi-networks.nix
  ];

  # helix editor + pinned disko from flake.lock (not fetched at install time)
  environment.systemPackages = [
    pkgs.helix
    inputs.disko.packages.${pkgs.system}.disko
  ];

  # Auto-login as nixos for convenience
  services.getty.autologinUser = "nixos";

  # Embed a snapshot of the nixconfig repo into the ISO at /etc/nixconfig.
  # Captured at ISO build time — no git or network access needed during install.
  environment.etc."nixconfig".source = builtins.path {
    name = "nixconfig";
    path = ../..;
  };

  # Pre-populate known_hosts for the nixos user so SSH to crisuflix during
  # install does not prompt for host key verification (which would break the
  # non-interactive install script under set -e).
  systemd.tmpfiles.rules = [
    "d /home/nixos/.ssh 0700 nixos users -"
    "C /home/nixos/.ssh/known_hosts 0644 nixos users - ${builtins.toFile "known_hosts" crisuflixKnownHosts}"
  ];

  # Install script available as 'run-install'
  environment.etc."install.sh".source = ./install.sh;
  environment.shellAliases.run-install = "bash /etc/install.sh";
}
