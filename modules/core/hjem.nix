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
      # Beets configuration file (used by docker container)
      "beets/config.yaml".source = dots + "/beets/config.yaml";
    };
  };
}
