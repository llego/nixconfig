{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    helix
    yazi
    lazygit

    # Nix stuff
    nixd
    alejandra
  ];

  environment.sessionVariables.EDITOR = "hx";
}
