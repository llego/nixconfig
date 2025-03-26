{
  pkgs,
  username,
  ...
}: {
  # Userspace packages
  home-manager.users.${username}.imports = [
    ./home-manager/desktop-apps.nix
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    nautilus
    gnome-text-editor
    gparted
    baobab
    nixd
    alejandra
  ];

  # Firefox
  programs.firefox = {
    enable = true;
    policies = {
      DisablePocket = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      DisplayBookmarksToolbar = "always";
      SearchBar = "unified";
      # EXTENSIONS
      # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/7?page=2
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
        # Bitwarden Password Manager:
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        # floccus:
        "floccus@handmadeideas.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/floccus/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  # Gnome Terminal
  #programs.gnome-terminal.enable = true;

  # nautilus-open-any-terminal
  # https://github.com/Stunkymonkey/nautilus-open-any-terminal
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
}
