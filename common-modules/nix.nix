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
  };

  # Required by nixd (LSP) when using flakes
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 20;
  # boot.loader.grub.configurationLimit = 10;

  nix.settings.trusted-users = ["root" "${username}" "@wheel"];
}
