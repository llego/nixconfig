{
  config,
  pkgs,
  ...
}: {
  ruuvi-binary = builtins.readFile (builtins.fetchurl {
    url = "https://github.com/Scrin/RuuviCollector/releases/download/v0.2.9/ruuvi-collector-0.2.jar";
  });

  home.file.ruuvi-binary = {
    enable = true;
    source = builtins.readFile (builtins.fetchurl {
      url = "https://github.com/Scrin/RuuviCollector/releases/download/v0.2.9/ruuvi-collector-0.2.jar";
    });
    target = "ruuvi/ruuvi-collector-0.2.jar";
  };

  home.file.ruuvi-names.properties = {
    enable = true;
    source = ./ruuvi-names.properties;
    target = "ruuvi/ruuvi-names.properties";
  };

  home.file.ruuvi-collector.properties = {
    enable = true;
    source = ./ruuvi-collector.properties;
    target = "ruuvi/ruuvi-collector.properties";
  };
}
