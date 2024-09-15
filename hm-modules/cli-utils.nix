{config, lib, pkgs, ...}:
{
	# Packages
	home.packages = [ 
	  pkgs.atool
	  pkgs.fzf
	  pkgs.ncdu
	  pkgs.htop
	  pkgs.wget
	  pkgs.curl
	  pkgs.lf
	  pkgs.yle-dl
	  pkgs.svtplay-dl
	  pkgs.tidal-dl
	  pkgs.dig
	  pkgs.tree
	  (pkgs.writeShellScriptBin "bandcamp-collection-downloader" (builtins.readFile ./bandcamp-collection-downloader/bandcamp-collection-downloader.sh))
  ];
  
  programs.fastfetch = { enable = true; settings = { }; };

  programs.fzf = { enable = true; enableZshIntegration = true; };

  programs.git = {
    enable = true;
    userEmail = "github.login@cri.su";
    userName = "llego";
  };
}
