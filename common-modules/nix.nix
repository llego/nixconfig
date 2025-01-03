{
  inputs,
  username,
  ...
}: {
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = true;
  };

  # Required by nixd (LSP) when using flakes
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 10;
  # boot.loader.grub.configurationLimit = 10;

  nix.settings.trusted-users = ["root" "${username}" "@wheel"];
}
