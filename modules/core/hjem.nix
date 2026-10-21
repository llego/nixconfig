{
  inputs,
  username,
  dots,
  ...
}: {
  imports = [inputs.hjem.nixosModules.default];

  hjem = {
    extraModules = [inputs.hjem-impure.hjemModules.default];

    clobberByDefault = true;

    users.${username} = {
      impure = {
        enable = true;
        dotsDir = "${dots}";
        dotsDirImpure = "/home/${username}/nixconfig/dots";
      };
      directory = "/home/${username}";

      xdg.config.files = {
        # Git SSH commit signature verification
        "git/allowed_signers".source = dots + "/git/allowed_signers";

        # OpenCode configuration files
        "opencode/opencode.json".source = dots + "/opencode/opencode.json";
        "opencode/AGENTS.md".source = dots + "/opencode/AGENTS.md";
      };
    };
  };
}
