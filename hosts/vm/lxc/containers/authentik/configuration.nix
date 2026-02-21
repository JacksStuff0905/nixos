{
  config,
  pkgs,
  inputs,
  util,
  lib,
  ...
}:
let
  file_to_not_import = [
  ];
in
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    networking.hostName = "ct-authentik";

    # Services
    srv.server = {
      authentik = {
        enable = true;
        secretsPath = ./secrets;

        deploy = {
          enable = true;
        };

        cleanup.enable = true;

        outposts = {
          proxy-outpost = {
            name = "Proxy Outpost";
            type = "proxy";
            managed = true;
            config = {
              authentik_host = "https://auth.srv.lan";
              authentik_host_insecure = false;
            };
          };

          ldap-outpost = {
            name = "LDAP Outpost";
            type = "ldap";
            managed = true;
            config = {
              authentik_host = "https://auth.srv.lan";
            };
          };
        };

        applications = {
          /*
            grafana = {
              name = "Grafana";
              description = "Monitoring Dashboard";
              group = "Infrastructure";
              launchUrl = "https://grafana.example.com";

              provider = {
                type = "oauth2";
                clientId = "grafana";
                redirectUris = [
                  "https://grafana.example.com/login/generic_oauth"
                ];
                scopes = [
                  "openid"
                  "email"
                  "profile"
                ];
              };

              accessControl = {
                allowedGroups = [
                  "admins"
                  "developers"
                ];
              };
            };
          */

          /*
            nextcloud = {
              name = "Nextcloud";
              launchUrl = "https://cloud.example.com";

              provider = {
                type = "oauth2";
                clientId = "nextcloud";
                redirectUris = [
                  "https://cloud.example.com/apps/oidc_login/oidc"
                ];
              };

              accessControl = {
                createGroup = true;
              };
            };
          */

          /*
            wiki = {
              name = "Internal Wiki";
              launchUrl = "https://wiki.example.com";

              provider = {
                type = "proxy";
                externalHost = "https://wiki.example.com";
                internalHost = "http://10.0.0.50:3000";
                mode = "forward_single";
              };
            };
          */

          filebrowser = {
            name = "Filebrowser";
            launchUrl = "https://drive.srv.lan";

            outpost = "proxy-outpost";

            provider = {
              type = "proxy";
              externalHost = "https://drive.srv.lan";
              mode = "forward_single";
            };

            accessControl = {
              createGroup = true;
            };
          };

          calibre = {
            name = "Calibre";
            launchUrl = "https://calibre.srv.lan";

            outpost = "proxy-outpost";

            provider = {
              type = "proxy";
              externalHost = "https://calibre.srv.lan";
              mode = "forward_single";
            };

            accessControl = {
              createGroup = true;
            };
          };

          wiki = {
            name = "Internal Wiki";
            launchUrl = "https://wiki.example.com";

            provider = {
              type = "proxy";
              externalHost = "https://wiki.example.com";
              internalHost = "http://10.0.0.50:3000";
              mode = "forward_single";
            };
          };
        };

        groups = {
          /*
            developers = {
              parent = "employees";
              attributes = {
                department = "Engineering";
              };
            };

            employees = { };

            "service-accounts" = {
              attributes = {
                description = "Service accounts for automation";
              };
            };

            "grafana-users" = { };

            "nextcloud-users" = { };
          */
        };

        users = {
          /*
            # Normal user - created once, password never overwritten
            # User can change their password and it persists
            johndoe = {
              name = "John Doe";
              email = "john.doe@example.com";
              groups = [
                "employees"
                "developers"
              ];
              # state = "created";  # default
              # managePassword = false;  # default
            };

            # Admin with initial password from env var
            # Password set on first create, then user manages it
            admin = {
              name = "Administrator";
              email = "admin@example.com";
              isSuperuser = true;
              groups = [ "admins" ];
              passwordEnvVar = "AUTHENTIK_BOOTSTRAP_ADMIN_PASSWORD";
              # state = "created";  # default - password only set once
            };

            # Service account with managed password
            # Password WILL be reset on every rebuild
            servicebot = {
              name = "Service Bot";
              email = "bot@example.com";
              type = "service_account";
              groups = [ "service-accounts" ];
              passwordEnvVar = "AUTHENTIK_SERVICEBOT_PASSWORD";
              managePassword = true; # Password controlled by NixOS
              state = "present"; # Update on every apply
            };

            # User that should be fully managed (rare use case)
            # All attributes including password reset on every rebuild
            managed-user = {
              name = "Managed User";
              email = "managed@example.com";
              groups = [ "employees" ];
              passwordEnvVar = "AUTHENTIK_MANAGED_USER_PASSWORD";
              managePassword = true;
              state = "present";
            };

            # User to be deleted
            olduser = {
              name = "Old User";
              email = "old@example.com";
              state = "absent";
            };
          */

          jacek = {
            name = "Jacek";
            email = "jacek.sawinski.0905@gmail.com";
            isSuperuser = true;
            groups = [
              "filebrowser"
              "calibre"
            ];
          };


          test = {
            name = "test";
            groups = [
            ];
          };
        };

        blueprints = {
          # Prompt passwordless users for password on first login
          "configure-password-on-login" = import ./blueprints/configure-password-on-login.nix;
        };
      };
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
