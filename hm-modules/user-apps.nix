{config, pkgs, username, git-email, ...}:
{
  # Packages
  home.packages = with pkgs; [ 
  
    # Desktop apps
    #(nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
    bitwarden-desktop
    protonmail-desktop
    trayscale
    vlc
    #gnome-tweaks
    #gnomeExtensions.blur-my-shell
    #gnomeExtensions.useless-gaps
    
    # cli
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
    
    # hyprland
    waybar
    
	];
	
  programs.git = {
    enable = true;
    userEmail = "${git-email}";
    userName = "${username}";
  };
	
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "fnaicdffflnofjppbagibeoednhnbjhg"; } # Floccus bookmarks sync
      { id = "cclelndahbckbenkjhflpdbgdldlbecc"; } # get cookies locally
      {
        id = "dcpihecpambacapedldabdbpakmachpb";
        updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
      }
    ];
  };
  
  programs.fastfetch = { enable = true; settings = { }; };

  programs.fzf = { enable = true; enableZshIntegration = true; };

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
#      dynamic_background_opacity = true;
      enable_audio_bell = false;
      mouse_hide_wait = "-1.0";
      window_padding_width = 10;
#      background_opacity = "0.5";
      background_blur = 10;
#      draw_minimal_borders = true;
      hide_window_decorations = true;
      window_margin_width = 5;
    };
  };
  
}
