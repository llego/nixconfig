{ config, ... }:

let
  net = config.christiansandbergNetwork;
in

{
  # Authelia authentication server
  services.authelia.instances.christiansandberg = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets.authelia-jwt.path;
      storageEncryptionKeyFile = config.age.secrets.authelia-storage.path;
      sessionSecretFile = config.age.secrets.authelia-session.path;
    };
    settings = {
      theme = "auto";
      default_2fa_method = "totp";

      server = {
        address = "tcp://${net.loopbackIP}:${toString net.autheliaPort}/";
      };

      log = {
        level = "info";
      };

      totp = {
        disable = false;
        issuer = net.domain;
        algorithm = "SHA1";
        digits = 6;
        period = 30;
        skew = 1;
        secret_size = 32;
      };

      webauthn = {
        disable = false;
      };

      authentication_backend = {
        password_reset = {
          disable = false;
        };
        file = {
          path = "/var/lib/authelia-christiansandberg/users_database.yml";
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
            domain = "*.${net.domain}";
            resources = ["^/api([/?].*)?$"];
            policy = "bypass";
          }
          {
            domain = "*.${net.domain}";
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
            domain = net.domain;
            authelia_url = "https://auth.${net.domain}";
            default_redirection_url = "https://${net.domain}";
            same_site = "lax";
          }
        ];
      };

      storage = {
        local = {
          path = "/var/lib/authelia-christiansandberg/db.sqlite3";
        };
      };

      notifier = {
        disable_startup_check = true;
        smtp = {
          address = "smtp://smtp.protonmail.ch:587";
          username = "mail@${net.domain}";
          sender = "Authelia <mail@${net.domain}>";
          subject = "[Authelia] {title}";
        };
      };
    };
    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.authelia-smtp.path;
    };
  };
}
