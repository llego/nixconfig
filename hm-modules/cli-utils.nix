{config, lib, pkgs, ...}:
{
	# Packages
	home.packages = [
		pkgs.atool
		pkgs.ncdu
		pkgs.htop
		pkgs.btop
		pkgs.wget
		pkgs.curl
		pkgs.lf
		pkgs.yle-dl
		pkgs.svtplay-dl
		pkgs.tidal-dl
		pkgs.dig
		pkgs.tree
		pkgs.neofetch
		(pkgs.writeShellScriptBin "bandcamp" (builtins.readFile ./bandcamp-collection/bandcamp-collection.sh))
	];
  
  programs.fastfetch = { enable = true; settings = { }; };

  programs.fzf = { enable = true; enableZshIntegration = true; };

  programs.git = {
    enable = true;
    userEmail = "github.login@cri.su";
    userName = "llego";
  };
}
