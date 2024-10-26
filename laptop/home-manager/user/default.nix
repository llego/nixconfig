{...}: {
  # Let Home Manager install and manage itself
  # programs.home-manager.enable = true;

  imports = [
    ./cli.nix
    ./zsh.nix
  ];

  #home.username = "${username}";
  #home.homeDirectory = "/home/${username}";

  #  fonts.fontconfig.enable = true;

  home.stateVersion = "24.05";
}
