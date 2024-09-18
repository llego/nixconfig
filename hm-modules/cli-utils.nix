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
	];
  
  programs.fastfetch = { enable = true; settings = { }; };

  programs.fzf = { enable = true; enableZshIntegration = true; };

  programs.git = {
    enable = true;
    userEmail = "github.login@cri.su";
    userName = "llego";
  };
}
