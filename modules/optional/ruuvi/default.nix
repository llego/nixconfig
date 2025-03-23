{
  config,
  pkgs,
  username,
  ...
}: {
  environment.systemPackages = [pkgs.jdk21_headless];

  security.wrappers = {
    hcitool = {
      owner = "root";
      group = "bleuser";
      capabilities = "cap_net_raw,cap_net_admin+eip"; #"cap_net_admin,cap_net_raw=ep";
      source = "/run/current-system/sw/bin/hcitool";
    };
    hcidump = {
      owner = "root";
      group = "bleuser";
      capabilities = "cap_net_raw,cap_net_admin+eip";
      source = "/run/current-system/sw/bin/hcidump";
    };
  };

  users.groups.bleuser = {};
  users.users.${username}.extraGroups = ["bleuser"];

  home-manager.users.${username} = {
    /*
    home.file.ruuvi-binary = {
      enable = true;
      source = builtins.fetchurl {
        url = "https://github.com/Scrin/RuuviCollector/releases/download/v0.2.9/ruuvi-collector-0.2.jar";
        sha256 = "1403032531b95f5acf3943eae4786ca085945e448fc020ddafd35f510791738d";
      };
      target = "ruuvi/ruuvi-collector-0.2.jar";
    };
    */
    home.file.ruuvi-names = {
      enable = true;
      source = ./ruuvi-names.properties;
      target = "ruuvi/ruuvi-names.properties";
    };

    home.file.ruuvi-collector = {
      enable = true;
      source = ./ruuvi-collector.properties;
      target = "ruuvi/ruuvi-collector.properties";
    };

    systemd.user.services = {
      ruuvi-collector = {
        Install = {
          WantedBy = ["multi-user.target"];
        };
        Unit = {
          After = "network.target";
          Description = "RuuviCollector Service";
        };
        Service = {
          ExecStart = "${pkgs.jdk21_headless}/bin/java -jar /home/${username}/ruuvi/ruuvi-collector-0.2.jar";
          Restart = "on-failure";
        };
      };
    };
  };
}
