{ config, pkgs, ...}:
{
  # Packages
  home.packages = with pkgs; [ 
    #(nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
    bitwarden-desktop
    protonmail-desktop
    trayscale
    vlc
    #gnome-tweaks
    #gnomeExtensions.blur-my-shell
    #gnomeExtensions.useless-gaps
    #kanshi
    #hyprpaper
	];
		
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
  
  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      #dynamic_background_opacity = true;
      enable_audio_bell = false;
      mouse_hide_wait = "-1.0";
      window_padding_width = 10;
      #background_opacity = "0.5";
      background_blur = 10;   # this is not working
      #draw_minimal_borders = true;
      hide_window_decorations = true;
      window_margin_width = 5;
      tab_bar_style = "slant";
      #linux_display_server = "X11";  # try to get rounded corners
    };
  };
  
}
