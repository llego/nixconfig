{
  config,
  lib,
  ...
}: let
  net = config.networkVars;
in {
  services.homepage-dashboard = {
    enable = true;
    listenPort = net.crisuflix.homepage.port;
    allowedHosts = "*";

    # Pass Unifi widget credentials from agenix secret.
    # The secret file contains: HOMEPAGE_VAR_UNIFI_PASSWORD=<password>
    # Referenced in widgets config as {{HOMEPAGE_VAR_UNIFI_PASSWORD}}.
    environmentFiles = [
      config.age.secrets.homepage-unifi-password.path
      config.age.secrets.homepage-gotify-key.path
    ];

    # Docker auto-discover: reads labels from all running containers
    docker = {
      my-docker.socket = "/var/run/docker.sock";
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
      {
        unifi_console = {
          url = "https://192.168.1.1";
          username = "homepage";
          password = "{{HOMEPAGE_VAR_UNIFI_PASSWORD}}";
        };
      }
    ];

    services = [
      {
        "Home automation" = [
          {
            homeassistant = {
              href = "https://ha.cri.su";
              icon = "home-assistant";
              description = "cri.su";
              siteMonitor = "http://192.168.1.101:${toString net.crisuflix.homeAssistant.port}";
            };
          }
          {
            esphome = {
              href = "https://esphome.llego.me";
              icon = "esphome";
              description = "llego.me";
              siteMonitor = "http://192.168.1.101:6052";
            };
          }
          {
            gotify = {
              href = "https://gotify.tailnet.cri.su";
              icon = "gotify";
              description = "tailnet.cri.su";
              siteMonitor = "https://gotify.tailnet.cri.su";
              widget = {
                type = "gotify";
                url = "https://gotify.tailnet.cri.su";
                key = "{{HOMEPAGE_VAR_GOTIFY_KEY}}";
              };
            };
          }
        ];
      }
      {
        Media = [
          {
            opencloud = {
              href = "https://cloud.cri.su";
              icon = "sh-opencloud";
              description = "cri.su";
              siteMonitor = "https://cloud.cri.su";
            };
          }
          {
            music-assistant = {
              href = "https://ma.cri.su";
              icon = "music-assistant";
              description = "cri.su";
              siteMonitor = "http://192.168.1.101:${toString net.crisuflix.musicAssistant.uiPort}";
            };
          }
        ];
      }
      {
        Infra = [
          {
            "dockge@llego.me" = {
              href = "https://dockge.llego.me";
              icon = "dockge";
              description = "llego.me";
            };
          }
          {
            headplane = {
              href = "https://headplane.cri.su/admin/";
              icon = "headscale";
              description = "cri.su";
              siteMonitor = "https://headplane.cri.su/admin/login";
            };
          }
          {
            unifi = {
              href = "https://unifi";
              icon = "unifi";
            };
          }
          {
            traefik = {
              href = "https://traefik.cri.su";
              icon = "traefik";
              description = "cri.su - vps";
            };
          }
        ];
      }
      {
        Monitoring = [
          {
            uptime-kuma = {
              href = "https://uptime.cri.su";
              icon = "uptime-kuma";
              description = "cri.su";
              siteMonitor = "https://uptime.cri.su";
            };
          }
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
      {
        Tools = [
          {
            "CUPS printing" = {
              href = "http://localhost:631/printers/";
              icon = "cups.png";
            };
          }
        ];
      }
    ];

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

  # Grant docker socket access for container auto-discover.
  # The NixOS module uses DynamicUser + PrivateUsers by default which blocks
  # supplementary group memberships. Override both to match the glances pattern.
  systemd.services.homepage-dashboard = {
    after = ["docker.service"];
    wants = ["docker.service"];
    serviceConfig = {
      PrivateUsers = lib.mkForce false;
      SupplementaryGroups = ["docker"];
      BindReadOnlyPaths = ["/var/run/docker.sock:/var/run/docker.sock"];
    };
  };
}
