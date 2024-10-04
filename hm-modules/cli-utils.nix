{config, pkgs, inputs, ...}:
{
	# Packages
	home.packages = with pkgs; [
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
    kitty
	];
  
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


  programs.git = {
    enable = true;
    userEmail = "github.login@cri.su";
    userName = "llego";
  };
}
