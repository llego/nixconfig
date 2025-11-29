{inputs, ...}: {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    settings = {
      # configure noctalia here; defaults will be deep merged with these attributes.
      dock = {
        enabled = false;
      };
      bar = {
        density = "default";
        position = "left";
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
          ];
          center = [
            {
              id = "Taskbar";
              colorizeIcons = false;
              hideMode = "hidden";
              onlyActiveWorkspaces = true;
              onlySameOutput = true;
            }
            {
              id = "Spacer";
              width = 20;
            }
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              id = "SystemMonitor";
              showCpuTemp = false;
            }
            {
              id = "Battery";
              alwaysShowPercentage = true;
              warningThreshold = 30;
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Tokyo Night";
      general = {
        avatarImage = "/home/drfoobar/.face";
        radiusRatio = 0.2;
        animationSpeed = 1.5;
      };
      location = {
        monthBeforeDay = true;
        name = "Helsinki, Finland";
      };
      wallpaper = {
        enabled = true;
        overviewEnabled = false;
      };
      calendar.cards = [
        {
          id = "timer-card";
          enabled = false;
        }
        {
          id = "banner-card";
          enabled = true;
        }
        {
          id = "calendar-card";
          enabled = true;
        }
      ];
    };
  };
}
