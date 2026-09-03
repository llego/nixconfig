{config, ...}: let
  net = config.networkVars;
  homepageGroups = {
    Infra = [
      {
        headplane = {
          href = "https://headplane.vpn.cri.su/admin/";
          icon = "headscale";
          description = "vpn.cri.su · tailnet-only";
          siteMonitor = "https://headplane.vpn.cri.su/admin/login";
        };
      }
      {
        unifi = {
          href = "https://192.168.1.1";
          icon = "unifi";
          description = "home lan · app auth";
        };
      }
      {
        traefik = {
          href = "https://traefik.vpn.cri.su";
          icon = "traefik";
          description = "vpn.cri.su · tailnet-only";
        };
      }
    ];

    Monitoring = [
      {
        uptime-kuma = {
          href = "https://uptime.vpn.cri.su";
          icon = "uptime-kuma";
          description = "vpn.cri.su · tailnet-only";
          siteMonitor = "https://uptime.vpn.cri.su";
        };
      }
      {
        glances = {
          href = "https://glances.vpn.cri.su";
          icon = "glances";
          description = "vpn.cri.su · tailnet-only";
          siteMonitor = "https://glances.vpn.cri.su";
        };
      }
    ];

    Media = [
      {
        music-assistant = {
          href = "https://ma.cri.su";
          icon = "music-assistant";
          description = "cri.su · app auth";
          siteMonitor = "http://${net.hosts.crisuflix}:${toString net.crisuflix.musicAssistant.uiPort}";
        };
      }
      {
        opencloud = {
          href = "https://cloud.cri.su";
          icon = "sh-opencloud";
          description = "cri.su · authelia oidc";
          siteMonitor = "https://cloud.cri.su";
        };
      }
    ];

    "Home automation" = [
      {
        gotify = {
          href = "https://gotify.vpn.cri.su";
          icon = "gotify";
          description = "vpn.cri.su · tailnet-only";
          siteMonitor = "https://gotify.vpn.cri.su";
          widget = {
            type = "gotify";
            url = "https://gotify.vpn.cri.su";
            key = "{{HOMEPAGE_VAR_GOTIFY_KEY}}";
          };
        };
      }
      {
        homeassistant = {
          href = "https://ha.cri.su";
          icon = "home-assistant";
          description = "cri.su · app auth";
          siteMonitor = "http://${net.hosts.crisuflix}:${toString net.crisuflix.homeAssistant.port}";
        };
      }
      {
        esphome = {
          href = "https://esphome.vpn.cri.su";
          icon = "esphome";
          description = "vpn.cri.su · tailnet-only";
          siteMonitor = "http://${net.hosts.crisuflix}:${toString net.crisuflix.esphome.uiPort}";
        };
      }
    ];

    Tools = [
      {
        "CUPS printing" = {
          href = "http://localhost:631/printers/";
          icon = "cups.png";
        };
      }
    ];
  };
  groupOrder = [
    "Infra"
    "Monitoring"
    "Media"
    "Home automation"
    "Downloads"
    "Tools"
  ];
  mkGroup = name: {${name} = homepageGroups.${name};};
  orderedGroups = builtins.filter (group: builtins.hasAttr group homepageGroups && homepageGroups.${group} != []) groupOrder;
  extraGroups = builtins.filter (group: !(builtins.elem group groupOrder) && homepageGroups.${group} != []) (builtins.attrNames homepageGroups);
in {
  services.homepage-dashboard = {
    enable = true;
    listenPort = net.vps.homepage.port;
    allowedHosts = "*";

    # The secret files contain HOMEPAGE_VAR_* environment variables used below.
    environmentFiles = [
      config.age.secrets.homepage-unifi-password.path
      config.age.secrets.homepage-gotify-key.path
    ];

    docker.crisuflix = {
      host = net.hosts.crisuflix;
      port = 2375;
    };

    settings = {
      title = "cri.su - homepage";
      color = "slate";
      layout = [
        {Infra = {};}
        {Monitoring = {};}
        {Media = {};}
        {"Home automation" = {};}
        {Downloads = {};}
        {Tools = {};}
      ];
    };

    widgets = [
      {
        glances = {
          href = "https://glances.vpn.cri.su";
          url = "http://${net.hosts.crisuflix}:${toString net.crisuflix.glances.port}";
          version = 4;
          cpu = true;
          mem = true;
          cputemp = true;
          uptime = true;
          diskUnits = "bytes";
          expanded = true;
        };
      }
      {
        unifi_console = {
          url = "https://192.168.1.1";
          username = "homepage";
          password = "{{HOMEPAGE_VAR_UNIFI_PASSWORD}}";
        };
      }
    ];

    services = map mkGroup (orderedGroups ++ extraGroups);

    bookmarks = [
      {
        "Cloud tools" = [
          {
            "Proton Mail" = [
              {
                icon = "si-protonmail";
                href = "https://mail.proton.me";
              }
            ];
          }
          {
            Todoist = [
              {
                icon = "si-todoist";
                href = "https://app.todoist.com";
              }
            ];
          }
          {
            Leakomatic = [
              {
                href = "https://cloud.leakomatic.com";
                icon = "mdi-water";
              }
            ];
          }
          {
            Instapaper = [
              {
                href = "https://www.instapaper.com/u";
                icon = "si-instapaper";
              }
            ];
          }
        ];
      }
      {
        "Cloud infra" = [
          {
            Tailscale = [
              {
                href = "https://login.tailscale.com/admin/machines";
                icon = "si-tailscale";
              }
            ];
          }
          {
            "Control D" = [
              {
                href = "https://controld.com/dashboard/statistics";
                icon = "mdi-dns";
              }
            ];
          }
          {
            "Hetzner Console" = [
              {
                href = "https://console.hetzner.com/projects";
                icon = "si-hetzner";
              }
            ];
          }
          {
            Zoner = [
              {
                href = "https://home.zoner.fi/my-products";
                icon = "mdi-alpha-z";
              }
            ];
          }
          {
            Bittivirta = [
              {
                href = "https://portal.bittivirta.fi/clientarea.php?action=services";
                icon = "mdi-server";
              }
            ];
          }
          {
            SimpleLogin = [
              {
                href = "https://app.simplelogin.io/dashboard/";
                icon = "si-simplelogin";
              }
            ];
          }
        ];
      }
    ];
  };
}
