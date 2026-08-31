{config, ...}: let
  net = config.networkVars;
in {
  # Authelia authentication server for cri.su domain
  services.authelia.instances."cri.su" = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets."authelia-cri.su-jwt".path;
      storageEncryptionKeyFile = config.age.secrets."authelia-cri.su-storage".path;
      sessionSecretFile = config.age.secrets."authelia-cri.su-session".path;
      oidcIssuerPrivateKeyFile = config.age.secrets."authelia-cri.su-oidc-private-key".path;
      oidcHmacSecretFile = config.age.secrets."authelia-cri.su-oidc-hmac".path;
    };
    settings = {
      theme = "auto";
      default_2fa_method = "totp";

      server = {
        address = "tcp://${net.hosts.loopback}:${toString net.vps.authelia.port}/";
      };

      log = {
        level = "info";
      };

      totp = {
        disable = false;
        issuer = "cri.su";
        algorithm = "SHA1";
        digits = 6;
        period = 30;
        skew = 1;
        secret_size = 32;
      };

      webauthn = {
        disable = false;
        enable_passkey_login = true;
        experimental_enable_passkey_uv_two_factors = true;
      };

      # User attribute definitions for custom OIDC claims
      definitions = {
        user_attributes = {
          sftpgo_role = {
            expression = ''"sftpgo_admins" in groups ? "admin" : "sftpgo_managers" in groups ? "manager" : "user"'';
          };
        };
      };

      authentication_backend = {
        password_reset = {
          disable = false;
        };
        file = {
          path = "/var/lib/authelia-cri.su/users_database.yml";
          watch = false;
          search = {
            email = false;
            case_insensitive = false;
          };
          password = {
            algorithm = "argon2";
            argon2 = {
              variant = "argon2id";
              iterations = 3;
              memory = 65536;
              parallelism = 4;
              key_length = 32;
              salt_length = 16;
            };
          };
        };
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = ["cri.su" "*.cri.su"];
            resources = ["^/api([/?].*)?$"];
            policy = "bypass";
          }
          {
            domain = ["cri.su" "*.cri.su"];
            policy = "two_factor";
          }
        ];
      };

      session = {
        name = "authelia_session";
        same_site = "lax";
        inactivity = "1h";
        expiration = "12h";
        remember_me = "1M";
        cookies = [
          {
            name = "authelia_session_cookie_name";
            domain = "cri.su";
            authelia_url = "https://auth.cri.su";
            default_redirection_url = "https://cri.su";
            same_site = "lax";
          }
        ];
      };

      storage = {
        local = {
          path = "/var/lib/authelia-cri.su/db.sqlite3";
        };
      };

      notifier = {
        disable_startup_check = true;
        smtp = {
          address = "smtp://smtp.protonmail.ch:587";
          username = "mail@christiansandberg.fi";
          # password is loaded from secret file via environment variable
          sender = "Authelia <mail@christiansandberg.fi>";
          subject = "[Authelia] {title}";
        };
      };

      # OIDC Provider Configuration
      identity_providers.oidc = {
        enable_client_debug_messages = false;
        minimum_parameter_entropy = 8;
        enforce_pkce = "public_clients_only";

        # CORS configuration for grimmory and other clients
        cors = {
          endpoints = ["authorization" "token" "revocation" "introspection"];
          allowed_origins = ["https://cri.su"];
          allowed_origins_from_client_redirect_uris = true;
        };

        lifespans.custom.opencloud_native = {
          access_token = "1h";
          id_token = "1h";
          refresh_token = "365d";
        };

        # Custom claims policies for OIDC clients
        claims_policies = {
          sftpgo = {
            id_token = ["preferred_username" "sftpgo_role"];
            custom_claims = {
              sftpgo_role = {};
            };
          };
          # grimmory = {
          # id_token = ["email" "preferred_username" "name"];
          # };
          grafana = {
            id_token = ["email" "name" "groups"];
          };
          opencloud = {
            id_token = ["email" "preferred_username" "name" "groups"];
          };
          headscale = {
            id_token = ["email" "groups"];
          };
        };

        # Custom scopes
        scopes = {
          sftpgo = {
            claims = ["sftpgo_role"];
          };
        };

        clients = [
          # Sparky
          {
            client_id = "sparky";
            client_name = "Sparky";
            client_secret = "$pbkdf2-sha512$310000$Y7642pQKzNOAWduaFNrGPw$6rpvk1luRb6ffdhUyz5mMyxH7txXRQihPwLg5Jlq1HZt6G/uBgmkKzkk9p5JUb63HYd1oiU1Dw9yRuntAgK.xA";
            public = false;
            authorization_policy = "two_factor";
            redirect_uris = [
              "https://sparky.cri.su/api/auth/sso/callback/authelia"
            ];
            scopes = ["openid" "profile" "email" "groups"];
            id_token_signed_response_alg = "RS256";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }
          # Open-WebUI
          {
            client_id = "AGBx2j1MXj9U8E-L9H8MvL1dCWbH7KE30espMYWaZw8EV5gMWHYWfrNsLrZtUjWep0KJwK-d";
            client_name = "Open-WebUI";
            client_secret = "$pbkdf2-sha512$310000$f5dY5z3DCYItB4t9Kzx5QA$Cm8IhYheUzfsKbDUqhpHrVzPYTxwnvox8HBVpV4KExuelx2Zg4lGDbK2ckDHPpxS2IizyskdfDSYM41zMS7SpQ";
            public = false;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://ai.cri.su/oauth/oidc/callback"
            ];
            scopes = ["openid" "profile" "email" "groups"];
            response_types = ["code"];
            grant_types = ["authorization_code"];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
          # Immich
          {
            client_id = "immich";
            client_name = "Immich";
            client_secret = "$pbkdf2-sha512$310000$YCAyVXxUoWLPHkxJ6XaoOw$FWpSPMOzSnmqzRZW5TfwvsqBhzHOcDXWbjiqUj62ojzv73bs11n/Aj5YzgDrFhmQmjMzePms9WUh/8T7bcDMxA";
            public = false;
            require_pkce = false;
            redirect_uris = [
              "https://immich.cri.su/auth/login"
              "https://immich.cri.su/user-settings"
              "app.immich:///oauth-callback"
            ];
            scopes = ["openid" "profile" "email"];
            response_types = ["code"];
            grant_types = ["authorization_code"];
            id_token_signed_response_alg = "RS256";
            userinfo_signed_response_alg = "RS256";
            token_endpoint_auth_method = "client_secret_post";
          }

          # grimmory
          {
            client_id = "grimmory";
            client_name = "Grimmory";
            client_secret = "$pbkdf2-sha512$310000$uRmVVt8CSjlrkM/7fzkUfQ$c98y9CGmpcAfYskrTop4f1sv0Oq6nJHHepyG5gXgj7W6zr/d.oGiY45wxZeM.hBt73mF3NhPOeGZwq.g6k8B4A";
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://grimmory.cri.su/oauth2-callback"
            ];
            scopes = ["openid" "profile" "email" "groups" "offline_access"];
            grant_types = ["authorization_code" "refresh_token"];
            token_endpoint_auth_method = "client_secret_post";
          }

          # Grafana
          {
            client_id = "grafana";
            client_name = "Grafana";
            client_secret = "$pbkdf2-sha512$310000$ApSo0BmJh4xEEH8cRhGxLQ$TOuQD8Ptsvzh5fFWNceTL1AKSbxZ7WNSEWjqRaDFKJW9JVuv6B6jsBgwiEQfzj77oiAvHMke2sQoovHU5a9eww";
            public = false;
            authorization_policy = "two_factor";
            claims_policy = "grafana";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://grafana.cri.su/login/generic_oauth"
            ];
            scopes = ["openid" "profile" "groups" "email"];
            access_token_signed_response_alg = "RS256";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }

          # Beszel
          {
            client_id = "beszel";
            client_name = "Beszel";
            client_secret = "$pbkdf2-sha512$310000$IfWIfZbxjcDOu8hPMK.qiw$qCJjIMAUYGFJsE1/tyPot9cZnbryvshy9mJE3uwwW7TcsZLOIirCzavVt7AhH8/GbmdMHXc2Kzla.Rn.eczIZw";
            public = false;
            authorization_policy = "two_factor";
            redirect_uris = [
              "https://beszel.cri.su/api/oauth2-redirect"
            ];
            scopes = ["openid" "email" "profile"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }

          # SFTPGo
          {
            client_id = "sftpgo";
            client_name = "SFTPGo";
            client_secret = "$pbkdf2-sha512$310000$XoXkhioq02N5hgenTacSNA$LPQx5N2JZpBU8gO.EwHugDZMXk40DGlf9DEK.UswypVpeDFXmHVuY1wQ30b5v8GOrPQJQQGG2.QtITS8MKHdWw";
            public = false;
            authorization_policy = "two_factor";
            claims_policy = "sftpgo";
            redirect_uris = [
              "https://sftpgo.cri.su/web/oidc/redirect"
              "https://sftpgo.cri.su/web/oauth2/redirect"
            ];
            scopes = ["openid" "profile" "email" "sftpgo"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }

          # Reitti
          {
            client_id = "reitti";
            client_name = "Reitti";
            client_secret = "$pbkdf2-sha512$310000$Bb2NZu5xkPE4Qlu/ffZpJw$BXlqbMz4sqz0ZEn6MsEkkccfpZlxqGHGXIiVnCDj18Al4JadJklNA0JxtuKgDnRpM4nW0CD/E.Nr0spOPwI8iQ";
            public = false;
            authorization_policy = "two_factor";
            consent_mode = "pre-configured";
            pre_configured_consent_duration = "1w";
            redirect_uris = [
              "https://reitti.cri.su/login/oauth2/code/oauth"
              "https://reitti.cri.su/login"
            ];
            scopes = ["openid" "profile"];
            grant_types = ["authorization_code" "refresh_token"];
            response_types = ["code"];
            response_modes = ["form_post" "query" "fragment"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }

          # OpenCloud — Web (browser)
          {
            client_id = "web";
            client_name = "OpenCloud";
            public = true;
            authorization_policy = "two_factor";
            claims_policy = "opencloud";
            require_pkce = true;
            pkce_challenge_method = "S256";
            consent_mode = "pre-configured";
            pre_configured_consent_duration = "1w";
            redirect_uris = [
              "https://cloud.cri.su/"
              "https://cloud.cri.su/oidc-callback.html"
              "https://cloud.cri.su/oidc-silent-redirect.html"
            ];
            scopes = ["openid" "profile" "email" "groups"];
            grant_types = ["authorization_code"];
            response_types = ["code"];
            response_modes = ["form_post" "query" "fragment"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }

          # OpenCloud — Desktop client
          {
            client_id = "OpenCloudDesktop";
            client_name = "OpenCloud Desktop";
            public = true;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            consent_mode = "pre-configured";
            pre_configured_consent_duration = "1w";
            lifespan = "opencloud_native";
            redirect_uris = [
              "http://127.0.0.1"
              "http://localhost"
            ];
            scopes = ["openid" "profile" "email" "groups" "offline_access"];
            grant_types = ["authorization_code" "refresh_token"];
            response_types = ["code"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }

          # OpenCloud — Android app
          {
            client_id = "OpenCloudAndroid";
            client_name = "OpenCloud Android";
            public = true;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            consent_mode = "pre-configured";
            pre_configured_consent_duration = "1y";
            lifespan = "opencloud_native";
            redirect_uris = ["oc://android.opencloud.eu"];
            scopes = ["openid" "profile" "email" "groups" "offline_access"];
            grant_types = ["authorization_code" "refresh_token"];
            response_types = ["code"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }

          # OpenCloud — iOS app
          {
            client_id = "OpenCloudIOS";
            client_name = "OpenCloud iOS";
            public = true;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            consent_mode = "pre-configured";
            pre_configured_consent_duration = "1y";
            lifespan = "opencloud_native";
            redirect_uris = ["oc://ios.opencloud.eu"];
            scopes = ["openid" "profile" "email" "groups" "offline_access"];
            grant_types = ["authorization_code" "refresh_token"];
            response_types = ["code"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }

          # Tidarr
          {
            client_id = "tidarr";
            client_name = "Tidarr";
            client_secret = "$pbkdf2-sha512$310000$tJLNjAM7uNx3LIbXtWr2Tg$tqdL3TxvOMnvg0HhyMVCAxwtitmAd1KWt8yT9qYNFaE/bK4ryguDoDm55gzIe5kFIquFvn1X.qFdZW3wjzg.uw";
            public = false;
            authorization_policy = "two_factor";
            redirect_uris = [
              "https://tidarr.cri.su/api/auth/oidc/callback"
            ];
            scopes = ["openid" "profile" "email"];
            response_types = ["code"];
            grant_types = ["authorization_code"];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }

          # Anchor Notes
          {
            client_id = "anchor";
            client_name = "Anchor Notes";
            public = true;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://anchor.cri.su/api/auth/oidc/callback"
              "anchor://oidc/callback"
            ];
            scopes = ["openid" "profile" "email"];
            response_types = ["code"];
            grant_types = ["authorization_code"];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }

          # Headscale / Headplane (shared client for perfect subject matching)
          {
            client_id = "headscale";
            client_name = "Headscale";
            client_secret = "$pbkdf2-sha512$310000$NEYIgTDGeG8NofQ.BwDAOA$qLdqcS4hHzNDY6QT8u7Ombg1iZmF/ZXYvP2BDa3LCOq6zCHpgElWClYJMLTql88pMlGPBoya0mvfqI3qzJU05g";
            public = false;
            authorization_policy = "two_factor";
            claims_policy = "headscale";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://headscale.cri.su/oidc/callback"
              "https://headplane.vpn.cri.su/admin/oidc/callback"
            ];
            scopes = ["openid" "profile" "email" "groups"];
            response_types = ["code"];
            grant_types = ["authorization_code"];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];
      };
    };
    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets."authelia-cri.su-smtp".path;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.authelia-cri-su = {
      rule = "Host(`auth.cri.su`)";
      entryPoints = ["websecure"];
      service = "authelia-cri-su";
      tls.certResolver = "hetzner";
    };

    services.authelia-cri-su.loadBalancer.servers = [
      {
        url = "http://${net.hosts.loopback}:${toString net.vps.authelia.port}";
      }
    ];

    middlewares.authelia-cri-su.forwardAuth = {
      address = "http://${net.hosts.loopback}:${toString net.vps.authelia.port}/api/authz/forward-auth?authelia_url=https%3A%2F%2Fauth.cri.su%2F";
      authResponseHeaders = ["Remote-User" "Remote-Groups" "Remote-Email" "Remote-Name"];
      trustForwardHeader = true;
    };
  };
}
