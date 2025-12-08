{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.blur-my-shell
    gnomeExtensions.useless-gaps
    gnomeExtensions.paperwm
  ];

  # Gnome settings
  dconf = {
    enable = true;
    settings = {
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer"];
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          blur-my-shell.extensionUuid
          #useless-gaps.extensionUuid
          paperwm.extensionUuid
        ];
      };
      "org/gnome/shell/extensions/blur-my-shell" = {
        brightness = 0.75;
        noise-amount = 0;
      };
      "org/gnome/desktop/wm/keybindings" = {
        show-desktop = ["<Super>d"];
        move-to-workspace-left = ["<Shift><Super>Left"];
        move-to-workspace-right = ["<Shift><Super>Right"];
        switch-to-workspace-1 = ["<Super>1"];
        switch-to-workspace-2 = ["<Super>2"];
        switch-to-workspace-3 = ["<Super>3"];
        switch-to-workspace-4 = ["<Super>4"];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        next = ["<Shift><Control>n"];
        previous = ["<Shift><Control>p"];
        play = ["<Shift><Control>space"];
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Alacritty";
        command = "alacritty";
        binding = "<Alt>Return";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Text editor";
        command = "gnome-text-editor";
        binding = "<Alt>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Nautilus";
        command = "nautilus";
        binding = "<Alt>f";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "Chromium";
        command = "chromium";
        binding = "<Alt>w";
      };
      #      "org/gnome/desktop/interface" = {
      #        color-scheme = "prefer-dark";
      #      };
      #      "org/gnome/desktop/interface" = {
      #        monospace-font-name = "JetBrainsMono Nerd Font 10";
      #      };
      #      "org/gnome/Console" = {
      #        custom-font = "JetBrainsMono Nerd Font 10";
      #      };
    };
  };

  # Application icons to Gnome menu
  targets.genericLinux.enable = true;
  xdg.mime.enable = true;
  xdg.systemDirs.data = ["${config.home.homeDirectory}/.nix-profile/share/applications"];

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/plain" = "gnome-text-editor.desktop";
    "x-scheme-handler/mailto" = "proton-mail.desktop";
    "text/html" = "chromium-browser.desktop";
    "application/xhtml+xml" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
  };
}
