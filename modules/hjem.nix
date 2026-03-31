{
  inputs,
  username,
  ...
}: {
  imports = [
    inputs.hjem.nixosModules.default
  ];

  hjem.clobberByDefault = true;

  hjem.users.${username} = {
    directory = "/home/${username}";

    xdg.config.files = {
      # Niri configuration files
      "niri/config.kdl".source = ./home/niri/config.kdl;

      # Helix configuration files
      "helix/config.toml".source = ./home/helix/config.toml;
      "helix/languages.toml".source = ./home/helix/languages.toml;
      "helix/themes/kanabox.toml".source = ./home/helix/themes/kanabox.toml;
      "helix/themes/noctalia.toml".source = ./home/helix/themes/noctalia.toml;

      # Yazi configuration files
      "yazi/yazi.toml".source = ./home/yazi/yazi.toml;
      "yazi/theme.toml".source = ./home/yazi/theme.toml;
      "yazi/flavors/eldritch.yazi/flavor.toml".source = ./home/yazi/flavors/eldritch.yazi/flavor.toml;
      "yazi/flavors/noctalia.yazi/flavor.toml".source = ./home/yazi/flavors/noctalia.yazi/flavor.toml;

      # Opencode configuration files
      "opencode/opencode.json".source = ./home/opencode/opencode.json;

      # Noctalia configuration files
      "noctalia/settings.json".source = ./home/noctalia/settings.json;
      "noctalia/wallpapers/wallhaven_p88g5j.jpg".source = ./home/noctalia/wallpapers/wallhaven_p88g5j.jpg;
      "noctalia/wallpapers/wallhaven_zm5pxv.jpg".source = ./home/noctalia/wallpapers/wallhaven_zm5pxv.jpg;
    };

    # SSH shortcuts (application desktop files)
    xdg.data.files = {
      "applications/ssh-christiansandberg.desktop".source = ./home/applications/ssh-christiansandberg.desktop;
      "applications/ssh-crisuflix.desktop".source = ./home/applications/ssh-crisuflix.desktop;
      "applications/ssh-nixvm.desktop".source = ./home/applications/ssh-nixvm.desktop;
      "applications/ssh-rpi3.desktop".source = ./home/applications/ssh-rpi3.desktop;
      "applications/ssh-rpi4.desktop".source = ./home/applications/ssh-rpi4.desktop;
      "applications/ssh-rpi5.desktop".source = ./home/applications/ssh-rpi5.desktop;
      "applications/ssh-rpizero.desktop".source = ./home/applications/ssh-rpizero.desktop;
      "applications/ssh-rpizero2.desktop".source = ./home/applications/ssh-rpizero2.desktop;
    };
  };
}
