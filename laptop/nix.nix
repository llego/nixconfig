{inputs, ...}: {
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Required by nixd (LSP) when using flakes
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
