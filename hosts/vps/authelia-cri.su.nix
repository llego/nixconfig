{ config, ... }:

let
  net = config.christiansandbergNetwork;
in

{
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
        address = "tcp://${net.loopbackIP}:${toString net.autheliaCriSuPort}/";
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
        inactivity = "5m";
        expiration = "1h";
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

        # CORS configuration for BookLore and other clients
        cors = {
          endpoints = ["authorization" "token" "revocation" "introspection"];
          allowed_origins = ["https://cri.su"];
          allowed_origins_from_client_redirect_uris = true;
        };

        # Custom claims policies for OIDC clients
        claims_policies = {
          sftpgo = {
            id_token = ["preferred_username" "sftpgo_role"];
            custom_claims = {
              sftpgo_role = {};
            };
          };
          booklore = {
            id_token = ["email" "preferred_username" "name"];
          };
        };

        # Custom scopes
        scopes = {
          sftpgo = {
            claims = ["sftpgo_role"];
          };
        };

        clients = [
          # Open-WebUI
          {
            client_id = "AGBx2j1MXj9U8E-L9H8MvL1dCWbH7KE30espMYWaZw8EV5gMWHYWfrNsLrZtUjWep0KJwK-d";
            client_name = "Open-WebUI";
            client_secret = "\$plaintext\$ldER8wLIo7rEC5vgwdzOQLcnGzyZpHO5MP0A1DvezEt6pGjRXWF11cY9MoGtiTNS";
            public = false;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://ai.cri.su/oauth/oidc/callback"
            ];
            scopes = ["openid" "profile" "email" "groups"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }

          # BookLore (public client with PKCE)
          {
            client_id = "booklore";
            client_name = "BookLore";
            public = true;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://booklore.cri.su/oauth2-callback"
            ];
            scopes = ["openid" "profile" "email" "offline_access"];
            response_types = ["code"];
            grant_types = ["authorization_code" "refresh_token"];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }

          # Grafana
          {
            client_id = "grafana";
            client_name = "Grafana";
            client_secret = "$pbkdf2-sha512$310000$ApSo0BmJh4xEEH8cRhGxLQ$TOuQD8Ptsvzh5fFWNceTL1AKSbxZ7WNSEWjqRaDFKJW9JVuv6B6jsBgwiEQfzj77oiAvHMke2sQoovHU5a9eww";
            public = false;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://grafana.cri.su/login/generic_oauth"
            ];
            scopes = ["openid" "profile" "groups" "email"];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }

          # Beszel
          {
            client_id = "beszel";
            client_name = "Beszel";
            client_secret = "$pbkdf2-sha512$310000$GPXWuisAtcDbDcmUvTpT.g$VZPsq8//6ajpLZstu1FAeB2f65c8uG3RVR308nmODNxYlYvATG4rcNkef/FKJ1rpnvBZo2xkKrkmcEhLM8simQ";
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
        ];
      };
    };
    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets."authelia-cri.su-smtp".path;
    };
  };
}
