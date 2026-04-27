{
  inputs,
  pkgs,
  ...
}: let
  githubKnownHosts = ''
    github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
    github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
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

  # Auto-login as nixos for convenience (already set by installation-device.nix,
  # but explicit here for clarity)
  services.getty.autologinUser = "nixos";

  # SSH key and known_hosts for the nixos user — baked in at build time from
  # crisuflix filesystem. Never committed to git (builtins.readFile is impure).
  # Placed in /home/nixos/.ssh/ so the nixos user's git/ssh can find them.
  systemd.tmpfiles.rules = [
    "d /home/nixos/.ssh 0700 nixos users -"
    "C /home/nixos/.ssh/id_ed25519     0600 nixos users - ${builtins.toFile "id_ed25519" (builtins.readFile /home/llego/.ssh/id_ed25519)}"
    "C /home/nixos/.ssh/id_ed25519.pub 0644 nixos users - ${builtins.toFile "id_ed25519.pub" (builtins.readFile /home/llego/.ssh/id_ed25519.pub)}"
    "C /home/nixos/.ssh/known_hosts    0644 nixos users - ${builtins.toFile "known_hosts" githubKnownHosts}"
  ];

  # Install script available as 'run-install'
  environment.etc."install.sh".source = ./install.sh;
  environment.shellAliases.run-install = "bash /etc/install.sh";
}
