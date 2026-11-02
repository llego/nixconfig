{pkgs, ...}: {
  imports = [./yazi.nix];

  # System packages
  environment.systemPackages = with pkgs; [
    btop
    ncdu
    opencode
    gh
    lazygit
    marksman
    (mdformat.withPlugins (ps: [ps.mdformat-gfm])) # markdown formatter with table support
    parted
    nitch
    usbutils
    atool
    bitwarden-cli

    # Nix stuff
    nixd
    alejandra
  ];
}
