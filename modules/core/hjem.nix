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
        # OpenCode configuration files
        "opencode/opencode.json".source = dots + "/opencode/opencode.json";
        "opencode/AGENTS.md".source = dots + "/opencode/AGENTS.md";
        "opencode/agent/code-reviewer.md".source = dots + "/opencode/agent/code-reviewer.md";
      };
    };
  };
}
