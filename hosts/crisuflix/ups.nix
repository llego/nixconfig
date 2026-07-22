{config, ...}: let
  net = config.networkVars;
in {
  networking.firewall.allowedTCPPorts = [
    net.crisuflix.nut.port # NUT (UPS monitoring)
  ];

  power.ups = {
    enable = true;
    mode = "standalone";

    ups."ups" = {
      driver = "usbhid-ups";
      port = "auto";
    };

    upsmon = {
      monitor."ups" = {
        user = "upsmon";
        powerValue = 1;
        system = "ups@localhost";
      };

      settings = {
        FINALDELAY = 5;
        NOTIFYFLAG = [
          ["ONLINE" "SYSLOG+WALL"]
          ["ONBATT" "SYSLOG+WALL"]
          ["LOWBATT" "SYSLOG+WALL+EXEC"]
          ["FSD" "SYSLOG+WALL+EXEC"]
          ["SHUTDOWN" "SYSLOG+WALL"]
          ["REPLBATT" "SYSLOG+WALL"]
        ];
      };
    };

    users.upsmon = {
      passwordFile = "/run/keys/nut-password";
      upsmon = "primary";
    };
  };
}
