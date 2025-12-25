{pkgs, ...}: {
  # System packages
  environment.systemPackages = with pkgs; [
    helix
    yazi

    # Nix stuff
    nixd
    alejandra
  ];

  environment.sessionVariables.EDITOR = "hx";
}
