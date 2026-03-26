# Frigate NVR module for crisuflix
# Migrated from Docker configuration
{ config, pkgs, lib, ... }:

let
  cfg = config.services.frigate;
in
{
  # Frigate NVR service
  services.frigate = {
    enable = true;
    hostname = "frigate.cri.su";
    vaapiDriver = "iHD";
    # Disable config check since env vars aren't available during build
    checkConfig = false;

    settings = {
      # Authentication disabled - handled by Traefik/Authelia on VPS
      auth = {
        enabled = false;
        failed_login_rate_limit = "1/second;5/minute;20/hour";
        trusted_proxies = [
          "127.0.0.1"
          "192.168.1.0/24"
          "100.64.0.0/10" # Tailscale
        ];
        cookie_secure = true;
      };

      proxy = {
        header_map = {
          user = "Remote-User";
        };
        default_role = "admin";
      };

      mqtt = {
        enabled = true;
        host = "192.168.1.103";
        port = 1883;
        user = "mqtt_user";
        password = "{FRIGATE_MQTT_PASSWORD}";
      };

      detectors = {
        coral = {
          type = "edgetpu";
          device = "usb";
        };
      };

      ffmpeg = {
        hwaccel_args = "preset-vaapi";
      };

      model = {
        path = "plus://6eed27e62b35757a2d1d87beee5aa05c";
      };

      semantic_search = {
        enabled = true;
        model_size = "small";
        reindex = false;
      };

      genai = {
        provider = "openai";
        api_key = "{FRIGATE_OPENAI_API_KEY}";
        model = "gpt-4o-mini";
      };

      go2rtc = {
        streams = {
          terrassen_rtsp = [
            "rtsp://dkTHnJFQ:IdEBPloBn4woy7KD@192.168.3.242:554/live/ch0"
          ];
          terrassen_rtsp_sub = [
            "rtsp://dkTHnJFQ:IdEBPloBn4woy7KD@192.168.3.242:554/live/ch1"
          ];
          sonoff_rtsp = [
            "rtsp://rtsp:6WBG8J3m@192.168.3.124:554/av_stream/ch0"
          ];
          sonoff_rtsp_sub = [
            "rtsp://rtsp:6WBG8J3m@192.168.3.124:554/av_stream/ch1"
          ];
          farstun_h264 = [
            "rtsp://rpizero2.home:8554/cam"
          ];
        };
      };

      cameras = {
        terrassen = {
          enabled = true;
          ffmpeg = {
            inputs = [
              {
                path = "rtsp://127.0.0.1:8554/terrassen_rtsp?video=copy&audio=aac";
                input_args = "preset-rtsp-restream";
                roles = [ "record" "detect" ];
              }
            ];
          };
          record = {
            enabled = true;
            alerts = {
              retain = {
                days = 365;
              };
            };
            detections = {
              retain = {
                days = 3650;
              };
            };
            continuous = {
              days = 90;
            };
            motion = {
              days = 0;
            };
          };
          detect = {
            width = 768;
            height = 432;
            fps = 2;
          };
          objects = {
            track = [ "person" "face" ];
            filters = {
              person = {
                threshold = 0.80;
              };
            };
            genai = {
              enabled = true;
              prompt = ''
                "Analysera sekvensen av bilder som innehåller {label}. 
                Fokusera på beteendet hos {label} baserat på dess handlingar och rörelser, 
                snarare än att beskriva dess utseende eller omgivning.
                Bilderna är tagna på vår terrass. Dörren till höger är hemmets bakdörr. Konstruktionen till vänster är en pergola.
                Om en person är iklädd en baddräkt är hen på väg för att ta ett dopp eller på väg tillbaka från ett dopp.
                Om personen inte är iklädd en baddräkt är hen definitivt inte på väg för att ta ett dopp eller på väg tillbaka från ett dopp — 
                i så fall ska du inte kommentera detta i ditt svar.
                Var koncis i ditt svar. Använd inte fler än 150 tecken i ditt svar."
              '';
            };
          };
          motion = {
            mask = [
              "0,0,0.618,0,0.617,0.322,0.341,0.238,0,0.363"
              "0.68,0.074,1,0.074,1,0,0.678,0"
            ];
          };
        };

        sonoff = {
          enabled = true;
          ffmpeg = {
            inputs = [
              {
                path = "rtsp://127.0.0.1:8554/sonoff_rtsp?video=copy&audio=aac";
                input_args = "preset-rtsp-restream";
                roles = [ "record" ];
              }
              {
                path = "rtsp://127.0.0.1:8554/sonoff_rtsp_sub?video=copy&audio=aac";
                input_args = "preset-rtsp-restream";
                roles = [ "detect" ];
              }
            ];
          };
          detect = {
            width = 640;
            height = 360;
            fps = 2;
          };
          record = {
            enabled = true;
            alerts = {
              retain = {
                days = 365;
              };
            };
            detections = {
              retain = {
                days = 365;
              };
            };
            continuous = {
              days = 90;
            };
            motion = {
              days = 0;
            };
          };
          objects = {
            track = [ "person" "face" ];
            filters = {
              person = {
                threshold = 0.70;
              };
            };
            genai = {
              enabled = false;
            };
          };
        };

        farstun = {
          enabled = false;
          mqtt = {
            timestamp = false;
            bounding_box = false;
            crop = true;
            quality = 100;
            height = 500;
          };
          ffmpeg = {
            inputs = [
              {
                path = "rtsp://127.0.0.1:8554/farstun_h264";
                input_args = "preset-rtsp-restream";
                roles = [ "detect" "record" ];
              }
            ];
          };
          detect = {
            width = 800;
            height = 600;
            fps = 2;
          };
          record = {
            enabled = true;
            alerts = {
              retain = {
                days = 365;
              };
            };
            detections = {
              retain = {
                days = 365;
              };
            };
            continuous = {
              days = 90;
            };
            motion = {
              days = 0;
            };
          };
          objects = {
            track = [ "person" "face" ];
            filters = {
              person = {
                threshold = 0.70;
              };
            };
            genai = {
              enabled = false;
            };
          };
        };
      };

      snapshots = {
        enabled = true;
        clean_copy = true;
        timestamp = false;
        bounding_box = true;
        crop = true;
        retain = {
          default = 90;
        };
        quality = 100;
      };

      birdseye = {
        enabled = true;
        width = 1280;
        height = 720;
        quality = 8;
        mode = "objects";
      };

      detect = {
        enabled = true;
      };

      face_recognition = {
        enabled = true;
        model_size = "small";
      };

      lpr = {
        enabled = false;
      };

      classification = {
        bird = {
          enabled = false;
        };
      };

      # TLS disabled - handled by Traefik reverse proxy
      tls = {
        enabled = false;
      };

      # Database path uses default (/var/lib/frigate)
      database = {
        path = "/var/lib/frigate/frigate.db";
      };

      # Recordings path
      record = {
        enabled = true;
        sync_recordings = true;
      };
    };

  };

  # Secrets configuration via systemd service
  age.secrets.frigate-env = {
    file = ./../secrets/frigate-env.age;
    owner = "frigate";
    group = "frigate";
    mode = "600";
  };

  # Enable Coral USB TPU support
  hardware.coral.usb.enable = true;

  # Intel GPU/VAAPI support
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # User and group setup for storage access
  users.users.frigate = {
    extraGroups = [ "video" "render" "apps" ];
  };

  # Bind mounts for storage locations
  systemd.services.frigate = {
    serviceConfig = {
      # Recordings on ZFS dataset
      BindPaths = [
        "/mnt/veckjarvi/frigate-storage:/var/lib/frigate/recordings"
      ];
      # Allow access to USB Coral device
      SupplementaryGroups = [ "coral" "video" "render" ];
      # Increase file limits for cameras
      LimitNOFILE = 65535;
      # Load secrets from environment file
      EnvironmentFile = config.age.secrets.frigate-env.path;
      # Add Coral library path
      Environment = [
        "LD_LIBRARY_PATH=${pkgs.libedgetpu}/lib"
      ];
    };
    unitConfig = {
      # Ensure storage is mounted before starting
      RequiresMountsFor = [ "/mnt/veckjarvi/frigate-storage" ];
    };
  };

  # Firewall configuration
  networking.firewall = {
    # Web UI (internal access, Traefik handles external)
    allowedTCPPorts = [
      5000  # Frigate web UI (internal)
      8554  # RTSP feeds
      8555  # WebRTC (TCP)
    ];
    allowedUDPPorts = [
      8555  # WebRTC (UDP)
    ];
    # Allow external access to Frigate through firewall
    extraInputRules = ''
      # Allow Frigate web UI access from local network and Tailscale
      ip saddr { 192.168.1.0/24, 100.64.0.0/10 } tcp dport 5000 accept comment "Frigate Web UI"
      # Allow RTSP access
      ip saddr { 192.168.1.0/24, 100.64.0.0/10 } tcp dport 8554 accept comment "Frigate RTSP"
      # Allow WebRTC
      ip saddr { 192.168.1.0/24, 100.64.0.0/10 } tcp dport 8555 accept comment "Frigate WebRTC TCP"
      ip saddr { 192.168.1.0/24, 100.64.0.0/10 } udp dport 8555 accept comment "Frigate WebRTC UDP"
    '';
  };

  # Ensure recordings directory exists
  systemd.tmpfiles.rules = [
    "d /mnt/veckjarvi/frigate-storage 0755 frigate frigate -"
    "d /var/lib/frigate 0755 frigate frigate -"
  ];
}
