{
  pkgs,
  username,
  git-email,
  ...
}: {
  # Packages
  home.packages = with pkgs; [
    atool
    btop
    neofetch
    bat
    lsd
    nitch
    fastfetch
    wlr-randr
    wdisplays
    unzip
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
    extraConfig.init.defaultBranch = "main";
  };
}
