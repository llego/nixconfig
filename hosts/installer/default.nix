{
  inputs,
  pkgs,
  ...
}: {
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

  # SSH keys baked in at build time from crisuflix — never committed to git
  environment.etc."root/.ssh/id_ed25519" = {
    source = builtins.toFile "id_ed25519" (builtins.readFile /home/llego/.ssh/id_ed25519);
    mode = "0600";
  };
  environment.etc."root/.ssh/id_ed25519.pub" = {
    source = builtins.toFile "id_ed25519.pub" (builtins.readFile /home/llego/.ssh/id_ed25519.pub);
    mode = "0644";
  };

  # Install script available as 'run-install'
  environment.etc."install.sh".source = ./install.sh;
  environment.shellAliases.run-install = "bash /etc/install.sh";
}
