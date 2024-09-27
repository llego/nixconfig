{config, pkgs,...}:
{
  # Install packages for everyone
  programs.zsh.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    nano
    home-manager
    nh
  ];

  # nano settings
  programs.nano.nanorc = ''
      set nowrap
      set tabstospaces
      set tabsize 2
  '';

  programs.gnome-terminal.enable = true;

}
