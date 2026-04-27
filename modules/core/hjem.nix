{
  inputs,
  username,
  ...
}: let
  dots = "${./dots}";
in {
  imports = [inputs.hjem.nixosModules.default];

  hjem.extraModules = [inputs.hjem-impure.hjemModules.default];

  hjem.users.${username} = {
    impure = {
      enable = true;
      dotsDir = dots;
      dotsDirImpure = "/home/${username}/nixconfig/modules/core/dots";
    };
    directory = "/home/${username}";

    xdg.config.files = {
      # Niri configuration files
      "niri/config.kdl".source = dots + "/niri/config.kdl";

      # Helix configuration files
      "helix/config.toml".source = dots + "/helix/config.toml";
      "helix/languages.toml".source = dots + "/helix/languages.toml";

      # Yazi configuration files
      "yazi/yazi.toml".source = dots + "/yazi/yazi.toml";
      "yazi/init.lua".source = dots + "/yazi/init.lua";
      "yazi/theme.toml".source = dots + "/yazi/theme.toml";
      "yazi/flavors/eldritch.yazi/flavor.toml".source = dots + "/yazi/flavors/eldritch.yazi/flavor.toml";

      # Beets configuration file
      "beets/config.yaml".source = dots + "/beets/config.yaml";

      # Opencode configuration files
      "opencode/opencode.json".source = dots + "/opencode/opencode.json";
      "opencode/AGENTS.md".source = dots + "/opencode/AGENTS.md";
      "opencode/agent/code-reviewer.md".source = dots + "/opencode/agent/code-reviewer.md";

      # Noctalia configuration files
      "noctalia/settings.json".source = dots + "/noctalia/settings.json";
      "noctalia/wallpapers/mountains4k.jpg".source = dots + "/noctalia/wallpapers/mountains4k.jpg";
      "noctalia/wallpapers/mountains.png".source = dots + "/noctalia/wallpapers/mountains.png";
      "noctalia/wallpapers/wallhaven_p88g5j.jpg".source = dots + "/noctalia/wallpapers/wallhaven_p88g5j.jpg";
      "noctalia/wallpapers/wallhaven_zm5pxv.jpg".source = dots + "/noctalia/wallpapers/wallhaven_zm5pxv.jpg";
      "noctalia/wallpapers/wallpaper-blue.jpg".source = dots + "/noctalia/wallpapers/wallpaper-blue.jpg";
    };

    # SSH shortcuts (application desktop files)
    xdg.data.files = {
      "applications/ssh-christiansandberg.desktop".source = dots + "/applications/ssh-christiansandberg.desktop";
      "applications/ssh-crisuflix.desktop".source = dots + "/applications/ssh-crisuflix.desktop";
      "applications/ssh-nixvm.desktop".source = dots + "/applications/ssh-nixvm.desktop";
      "applications/ssh-rpi3.desktop".source = dots + "/applications/ssh-rpi3.desktop";
      "applications/ssh-rpi4.desktop".source = dots + "/applications/ssh-rpi4.desktop";
      "applications/ssh-rpi5.desktop".source = dots + "/applications/ssh-rpi5.desktop";
      "applications/ssh-rpizero.desktop".source = dots + "/applications/ssh-rpizero.desktop";
      "applications/ssh-rpizero2.desktop".source = dots + "/applications/ssh-rpizero2.desktop";
    };
  };
}
