{config, pkgs, ...}:
{
  # Packages
  home.packages = with pkgs; [ 
    # Desktop apps
    bitwarden-desktop
    protonmail-desktop
    trayscale
    vlc
    gnome-tweaks
    gnomeExtensions.blur-my-shell
    
    # cli
		atool
		ncdu
		htop
		btop
		wget
		curl
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
#    (nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
	];
	
  programs.git = {
    enable = true;
    userEmail = "github.login@cri.su";
    userName = "llego";
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
      dynamic_background_opacity = true;
      enable_audio_bell = false;
      mouse_hide_wait = "-1.0";
      window_padding_width = 10;
#      background_opacity = "0.5";
#      background_blur = 5;
    };
  };
  
}
