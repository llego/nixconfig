{config, lib, pkgs, ...}:
{
	# Packages
	home.packages = [ 
		pkgs.bitwarden-desktop
		pkgs.protonmail-desktop
	  pkgs.trayscale
	  pkgs.vlc
	  (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
  ];
}
