{ config, pkgs, username, git-email, ...}:
{
  # Packages
  home.packages = with pkgs; [ 
    atool
    ncdu
    btop
    lf
    yle-dl
    svtplay-dl
    tidal-dl
    dig
    tree
    neofetch
    bat
    lsd
    nitch
    fastfetch
  ];
 
  # vim
  programs.vim = {
    enable = true;
    extraConfig = ''
      set clipboard+=unnamedplus
      set tabstop=2
      set expandtab
      set shiftwidth=2 smarttab
      set autoindent
      set cursorcolumn
      set cursorline
    '';
  };

  # git
  programs.git = {
    enable = true;
    userEmail = "${git-email}";
    userName = "${username}";
  };

  # tidal-dl configuration
  home.file.tidal-dl-conf = {
    enable = true;
    source = ../assets/.tidal-dl.json;
    target = ".tidal-dl.json";
  };

}
