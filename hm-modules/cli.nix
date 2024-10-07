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
  ];
  
  programs.git = {
    enable = true;
    userEmail = "${git-email}";
    userName = "${username}";
  };

  programs.fastfetch = { enable = true; settings = { }; };

  programs.fzf = { enable = true; enableZshIntegration = true; };

}
