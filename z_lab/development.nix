{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    helix
    yazi
    lazygit
    claude-code

    # Nix stuff
    nixd
    alejandra
  ];

  environment.sessionVariables.EDITOR = "hx";
}
