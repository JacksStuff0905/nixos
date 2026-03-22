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

        additional_uris = mkOption {
          type = listOf str;
          default = [ ];
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
  imports = [
    ./lldap.nix
    ./kanidm.nix
    ./openldap.nix
  ];

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

    access = {
      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      admins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };

    smtp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      address = lib.mkOption {
        type = lib.types.str;
      };

      username = lib.mkOption {
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

      smtp-password = lib.mkOption {
        type = lib.types.str;
        default = "authelia-smtp-password.age";
      };
    };

    ldap = {
      enable = lib.mkEnableOption "ldap";

      backend = lib.mkOption {
        type = lib.types.enum [
          "lldap"
          "kanidm"
          "openldap"
        ];
        default = "lldap";
      };

      secret = {
        authelia-password = lib.mkOption {
          type = lib.types.str;
          default = "lldap-user-password.age";
        };

        jwt-secret = lib.mkOption {
          type = lib.types.str;
          default = "lldap-jwt-secret.age";
        };
      };

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
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      mkUrl = proto: name: "${proto}://${name}.${cfg.url.domain}";

      basedn = builtins.concatStringsSep "," (
        builtins.map (d: "dc=${d}") (lib.splitString "." cfg.url.domain)
      );

      uid =
        {
          "lldap" = "uid";
          "openldap" = "cn";
        }
        ."${cfg.ldap.backend}";
    in
    {
      srv.server.authelia.ldap.secret.directory = lib.mkDefault cfg.secret.directory;

      users.groups.authelia-main = {
        gid = lib.mkForce 3003;
      };

      users.users.authelia-main = {
        isSystemUser = true;
        uid = lib.mkForce 3002;
        group = "authelia-main";
        extraGroups = [
          "lldap"
          "openldap"
        ];
      };

      age.secrets = lib.mkMerge [
        {
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

          authelia-ldap-password = {
            file = cfg.secret.directory + ("/" + cfg.secret.ldap-password);
            owner = "authelia-main";
            group = "authelia-main";
          };

          authelia-smtp-password = {
            file = cfg.secret.directory + ("/" + cfg.secret.smtp-password);
            owner = "authelia-main";
            group = "authelia-main";
          };
        }
      ];

      services.authelia.instances.main = {
        enable = true;

        environmentVariables = {
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = lib.mkIf (cfg.ldap.enable) config.age.secrets.authelia-ldap-password.path;
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.authelia-smtp-password.path;
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

          authentication_backend.file = lib.mkIf (!cfg.ldap.enable) {
            path = "/var/lib/authelia-main/users.yml";
          };

          authentication_backend.ldap = lib.mkIf cfg.ldap.enable {
            implementation = "custom";
            # Connect to local LLDAP instance
            address = "ldap://127.0.0.1:${toString cfg.ldap.ports.ldap}";
            timeout = "5s";
            start_tls = false;

            base_dn = basedn;

            # LLDAP admin user
            user = "${uid}=authelia,ou=services,${basedn}";
            password.algorithm = "plaintext";
            #password = "file://${config.age.secrets.lldap-user-password.path}";

            # LLDAP uses 'ou=people' for users
            additional_users_dn = "ou=people";
            users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))";

            # LLDAP uses 'ou=groups' for groups
            additional_groups_dn = "ou=groups";
            groups_filter = "(member={dn})";

            # Attribute mappings
            attributes = {
              username = "${uid}";
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
                domain = builtins.map (d: "${d}.${cfg.url.domain}") cfg.access.admins;
                policy = "one_factor";
                subject = [ "group:admins" ];
              }
              {
                domain = builtins.map (d: "${d}.${cfg.url.domain}") cfg.access.users;
                policy = "one_factor";
                subject = [ "group:users" ];
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
            disable_startup_check = false;
            smtp = {
              address = cfg.smtp.address;
              username = ''${cfg.smtp.username}'';
              sender = ''${cfg.smtp.username}'';
              subject = "[Authelia] {title}";
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
                ]
                ++ (builtins.map (u: "https://${c.id}.${cfg.url.domain}/${u}") c.additional_uris);

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
          (lib.mkIf (cfg.ldap.enable) [
            cfg.ldap.ports.http
            cfg.ldap.ports.ldap
          ])
          [ cfg.port ]
        ]
      );
    }
  );
}
