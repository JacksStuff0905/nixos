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
    networking.hostName = "ct-authelia";

    # Services
    srv.server = {
      authelia = {
        enable = true;
        secret.directory = ../../../../../secrets/authelia;
        url = {
          name = "auth";
          domain = "srv.lan";
        };

        smtp = {
          enable = true;
          address = "submissions://smtp.gmail.com:465";
          username = "jacek.sawinski.0905@gmail.com";
        };

        ldap = {
          enable = true;
          backend = "openldap";
          url.name = "users";

          openldap = {
            secretsFile = ../../../../../secrets/authelia/openldap-secrets.age;
            users = [
              {
                name = "jacek";
                email = "$U_JACEK_EMAIL";
                password = "$U_JACEK_PASSWORD";
              }
              {
                name = "julek";
                email = "$U_JULEK_EMAIL";
              }
              {
                name = "magda";
                email = "$U_MAGDA_EMAIL";
              }
            ];
          };
        };

        access = {
          admins = [
            "dns"
            "proxy"
          ];
          users = [
            "calibre"
            "drive"
            "photos"
          ];
        };

        clients.oidc = [
          {
            id = "photos";
            name = "Immich";
            secret = "$pbkdf2-sha512$310000$izJBYqkLgpu9OJVNvUu9sQ$kZ4rt/TkV7F/8dQ6hjb1oPO1b6Ma2f091Dvw61bLcyeKKMJXvtqtlS9YEsgn83l8VdufNoFoTK6xT2xYQyDcww";
          }
          {
            id = "vpn";
            name = "Firezone";
            secret = "$pbkdf2-sha512$310000$8WIU4tt3mwSLIZfPE5XbNw$RqxIVRQDF2YwrF0G/LaSyfsqkerDnKraPrQFfVMQokwdq6rlmIsVntY7vKm7tY2QvcNV.z6kyQCTFw1ul2ggbg";

            additional_uris = [
              "auth/oidc/callback"
            ];
          }
        ];
        /*
          secretFile = ./secrets/authentik-secret.age;
          oauth2SecretFile = ./secrets/oauth2-secrets/env-secrets.age;

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
              managed = false;
              config = {
                authentik_host = "https://auth.srv.lan";
              };
            };
          };

          applications = {
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

            immich = {
              name = "Immich";
              launchUrl = "https://photos.srv.lan";

              provider = {
                type = "oauth2";
                clientId = "immich";
                redirectUris = [
                  "https://photos.srv.lan/apps/oidc_login/oidc"
                ];
              };

              accessControl = {
                createGroup = true;
              };
            };

          };

          groups = {
          };

          users =
            let
              defaultGroups = [
                "filebrowser"
                "calibre"
                "samba"
                "immich"
              ];
            in
            {
              jacek = {
                name = "Jacek";
                email = "jacek.sawinski.0905@gmail.com";
                isSuperuser = true;
                groups = defaultGroups;
              };

              julek = {
                name = "Julek";
                groups = defaultGroups;
              };
            };

          blueprints = {
            "configure-password-on-login" = import ./blueprints/configure-password-on-login.nix;
          };
        */
      };
    };

    networking.firewall.enable = false;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
