{
  inputs,
  username,
  ...
}: {
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = true;
      trusted-users = ["root" "${username}" "@wheel"];
    };
    # Required by nixd (LSP) when using flakes
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 10;
  # boot.loader.grub.configurationLimit = 10;

  # Nano settings
  programs.nano = {
    enable = true;
    nanorc = builtins.readFile ./nix.nanorc;
  };

  # not another nix helper
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nixconfig";
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
