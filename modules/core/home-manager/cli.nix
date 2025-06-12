{
  pkgs,
  username,
  ...
}: {
  # Packages
  home.packages = with pkgs; [
    atool
    btop
    bat
    lsd
    nitch
    wlr-randr
    wdisplays
  ];

  # git
  programs.git = {
    enable = true;
    userEmail = "github.login@cri.su";
    userName = "${username}";
    extraConfig.init.defaultBranch = "main";
  };
}
