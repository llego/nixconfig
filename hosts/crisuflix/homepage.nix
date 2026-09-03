{
  config,
  lib,
  ...
}: let
  net = config.networkVars;
  homepageGroups = config.local.homepageServices;
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
  options.local = {
    homepageServices = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.attrs);
      default = {};
      description = "Homepage service entries grouped by Homepage section.";
    };

    homepageWidgets = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Homepage widget entries contributed by local service modules.";
    };
  };

  config = {
    local.homepageServices = {
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
      ];

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
            href = "https://unifi";
            icon = "unifi";
            description = "unifi · app auth";
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

    networking.firewall.allowedTCPPorts = [
      net.crisuflix.homepage.port # Homepage dashboard (for VPS Traefik)
    ];

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

      widgets =
        config.local.homepageWidgets
        ++ [
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
  };
}
