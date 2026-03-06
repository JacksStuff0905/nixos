{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "authelia";

  cfg = config.srv.server."${name}";

  types = with lib; {
    oidc-client = lib.types.submodule {
      options = with lib.types; {
        id = mkOption {
          type = str;
        };
        name = mkOption {
          type = str;
        };
        secret = mkOption {
          type = str;
        };

        public = mkOption {
          type = bool;
          default = false;
        };

        authorization_policy = mkOption {
          type = enum [
            "one_factor"
            "two_factor"
          ];
          default = "one_factor";
        };

        scopes = mkOption {
          type = listOf str;
          default = [
            "openid"
            "profile"
            "email"
          ];
        };
      };
    };
  };
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9091;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    clients = {
      oidc = lib.mkOption {
        type = lib.types.listOf types.oidc-client;
        default = [ ];
      };
    };

    url = {
      domain = lib.mkOption {
        type = lib.types.str;
      };
      name = lib.mkOption {
        type = lib.types.str;
      };
    };

    secret = {
      directory = lib.mkOption {
        type = lib.types.path;
      };

      jwt-secret = lib.mkOption {
        type = lib.types.str;
        default = "authelia-jwt-secret.age";
      };

      storage-key = lib.mkOption {
        type = lib.types.str;
        default = "authelia-storage-key.age";
      };

      ldap-password = lib.mkOption {
        type = lib.types.str;
        default = "lldap-user-password.age";
      };

      oidc-hmac = lib.mkOption {
        type = lib.types.str;
        default = "authelia-oidc-hmac.age";
      };

      oidc-private-key = lib.mkOption {
        type = lib.types.str;
        default = "authelia-oidc-private-key.age";
      };
    };

    lldap = {
      enable = lib.mkEnableOption "lldap";

      url = {
        proto = lib.mkOption {
          type = lib.types.enum [
            "http"
            "https"
          ];
          default = "https";
        };
        name = lib.mkOption {
          type = lib.types.str;
        };
      };

      ports = {
        http = lib.mkOption {
          type = lib.types.int;
          default = 17170;
        };

        ldap = lib.mkOption {
          type = lib.types.int;
          default = 3890;
        };
      };

      secret = {
        directory = lib.mkOption {
          type = lib.types.path;
        };

        jwt-secret = lib.mkOption {
          type = lib.types.str;
          default = "lldap-jwt-secret.age";
        };

        user-password = lib.mkOption {
          type = lib.types.str;
          default = "lldap-user-password.age";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      mkUrl = proto: name: "${proto}://${name}.${cfg.url.domain}";

      basedn = builtins.concatStringsSep "," (
        builtins.map (d: "dc=${d}") (lib.splitString "." cfg.url.domain)
      );
    in
    {
      srv.server.authelia.lldap.secret.directory = lib.mkDefault cfg.secret.directory;

      users.groups.authelia-main = {
        gid = lib.mkForce 3003;
      };

      users.users.authelia-main = {
        isSystemUser = true;
        uid = lib.mkForce 3002;
        group = "authelia-main";
        extraGroups = [
          "lldap"
        ];
      };

      age.secrets = {
        authelia-jwt-secret = {
          file = cfg.secret.directory + ("/" + cfg.secret.jwt-secret);
          owner = "authelia-main";
          group = "authelia-main";
        };
        authelia-storage-key = {
          file = cfg.secret.directory + ("/" + cfg.secret.storage-key);
          owner = "authelia-main";
          group = "authelia-main";
        };

        lldap-jwt-secret = {
          file = cfg.secret.directory + ("/" + cfg.lldap.secret.jwt-secret);
          owner = "authelia-main";
          group = "authelia-main";
        };
        lldap-user-password = {
          file = cfg.secret.directory + ("/" + cfg.lldap.secret.user-password);
          owner = "authelia-main";
          group = "authelia-main";
        };

        # New OIDC secrets
        authelia-oidc-hmac = {
          file = cfg.secret.directory + ("/" + cfg.secret.oidc-hmac);
          owner = "authelia-main";
          group = "authelia-main";
        };
        authelia-oidc-private-key = {
          file = cfg.secret.directory + ("/" + cfg.secret.oidc-private-key);
          owner = "authelia-main";
          group = "authelia-main";
        };
      };

      systemd.services.lldap.serviceConfig = {
        User = lib.mkForce "authelia-main";
        Group = lib.mkForce "authelia-main";
      };

      services.lldap = lib.mkIf cfg.lldap.enable {
        enable = true;

        settings = {
          http_host = "0.0.0.0";
          http_port = cfg.lldap.ports.http;

          force_ldap_user_pass_reset = "always";

          ldap_host = "0.0.0.0";
          ldap_port = cfg.lldap.ports.ldap;

          ldap_base_dn = basedn;
          #"dc=example,dc=com";

          # Public URL for LLDAP web UI (users access this to change passwords)
          http_url = mkUrl cfg.lldap.url.proto cfg.lldap.url.name;
        };

        environment = {
          LLDAP_JWT_SECRET_FILE = config.age.secrets.lldap-jwt-secret.path;
          LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.lldap-user-password.path;
        };
      };

      services.authelia.instances.main = {
        enable = true;

        environmentVariables = {
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.lldap-user-password.path;
        };

        # Secret files - create these manually or use agenix/sops-nix
        secrets = {
          jwtSecretFile = config.age.secrets.authelia-jwt-secret.path;
          storageEncryptionKeyFile = config.age.secrets.authelia-storage-key.path;
          oidcHmacSecretFile = config.age.secrets.authelia-oidc-hmac.path;
          oidcIssuerPrivateKeyFile = config.age.secrets.authelia-oidc-private-key.path;
        };

        settings = {
          server = {
            address = "tcp://0.0.0.0:${toString cfg.port}";
          };

          authentication_backend.refresh_interval = "5m";

          authentication_backend.file = lib.mkIf (!cfg.lldap.enable) {
            path = "/var/lib/authelia-main/users.yml";
          };

          authentication_backend.ldap = lib.mkIf cfg.lldap.enable {
            implementation = "custom";
            # Connect to local LLDAP instance
            address = "ldap://127.0.0.1:${toString cfg.lldap.ports.ldap}";
            timeout = "5s";
            start_tls = false;

            base_dn = basedn;

            # LLDAP admin user
            user = "uid=admin,ou=people,${basedn}";
            #password = "file://${config.age.secrets.lldap-user-password.path}";

            # LLDAP uses 'ou=people' for users
            additional_users_dn = "ou=people";
            users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))";

            # LLDAP uses 'ou=groups' for groups
            additional_groups_dn = "ou=groups";
            groups_filter = "(member={dn})";

            # Attribute mappings
            attributes = {
              username = "uid";
              mail = "mail";
              display_name = "displayName";
              group_name = "cn";
            };
          };

          access_control = {
            default_policy = "deny";

            rules = [
              {
                domain = "${cfg.url.name}.${cfg.url.domain}";
                policy = "bypass";
                resources = [
                  "^/api/.*$"
                  "^/jwks.json$"
                  "^/.well-known/.*$"
                  "^/[a-zA-Z0-9]+/.well-known/.*$"
                  "^/static/.*$"
                ];
              }
              {
                domain = "*.${cfg.url.domain}";
                policy = "one_factor";
                #subject = [ "group:users" ];
              }
            ];
          };

          session = {
            cookies = [
              {
                domain = cfg.url.domain;
                authelia_url = mkUrl "https" cfg.url.name;
              }
            ];
          };

          storage = {
            local = {
              path = "/var/lib/authelia-main/db.sqlite3";
            };
          };

          notifier = {
            filesystem = {
              filename = "/var/lib/authelia-main/notifications.txt";
            };
          };

          # OIDC Configuration
          identity_providers = {
            oidc = {
              # Token lifespans
              access_token_lifespan = "1h";
              authorize_code_lifespan = "1m";
              id_token_lifespan = "1h";
              refresh_token_lifespan = "90m";

              # OIDC clients
              clients = builtins.map (c: {
                client_id = c.id;
                client_name = c.name;
                client_secret = c.secret;
                public = c.public;
                authorization_policy = c.authorization_policy;

                token_endpoint_auth_method = "client_secret_basic";

                require_pkce = true;

                redirect_uris = [
                  "https://${c.id}.${cfg.url.domain}/auth/login"
                  "https://${c.id}.${cfg.url.domain}/user-settings"
                  "app.${c.id}:/" # Mobile app callback
                ];

                scopes = [
                  "openid"
                  "profile"
                  "email"
                ];

                grant_types = [
                  "authorization_code"
                ];

                response_types = [
                  "code"
                ];

                userinfo_signed_response_alg = "none";
              }) cfg.clients.oidc;
            };
          };
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall (
        lib.mkMerge [
          (lib.mkIf (cfg.lldap.enable) [
            cfg.lldap.ports.http
            cfg.lldap.ports.ldap
          ])
          [ cfg.port ]
        ]
      );
    }
  );
}
