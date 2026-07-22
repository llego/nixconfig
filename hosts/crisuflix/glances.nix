{
  config,
  lib,
  ...
}: let
  net = config.networkVars;
in {
  services.glances = {
    enable = true;
    port = net.crisuflix.glances.port;
    openFirewall = true;
    extraArgs = ["--webserver" "--time" "5"];
  };

  # Run as apps user to read Docker and host disk state.
  systemd.services.glances.serviceConfig = {
    User = "apps";
    Group = "apps";
    DynamicUser = lib.mkForce false;
    SupplementaryGroups = ["docker"];
    BindReadOnlyPaths = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/:/rootfs:ro"
    ];
    ProtectSystem = lib.mkForce false;
    ProtectHome = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    ReadWritePaths = lib.mkForce ["/var/log" "/" "/mnt"];
  };

  local.homepageWidgets = [
    {
      glances = {
        href = "https://glances.cri.su";
        url = "http://192.168.1.101:${toString net.crisuflix.glances.port}";
        version = 4;
        cpu = true;
        mem = true;
        cputemp = true;
        uptime = true;
        diskUnits = "bytes";
        expanded = true;
      };
    }
  ];

  local.homepageServices.Monitoring = [
    {
      glances = {
        href = "https://glances.cri.su";
        icon = "glances";
        description = "cri.su";
        siteMonitor = "https://glances.cri.su";
      };
    }
  ];
}
