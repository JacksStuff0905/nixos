{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.srv.server.authelia;

  mkUrl = proto: name: "${proto}://${name}.${cfg.url.domain}";

  kanidm-package = pkgs.kanidmWithSecretProvisioning_1_9;

  basedn = builtins.concatStringsSep "," (
    builtins.map (d: "dc=${d}") (lib.splitString "." cfg.url.domain)
  );

  types = with lib; {
    ldap-service = lib.types.submodule {
      options = with lib.types; {
        name = mkOption {
          type = str;
        };

        password = mkOption {
          type = either str path;
        };
      };
    };
  };
in
{
  options.srv.server.authelia.ldap.kanidm = {
    services = lib.mkOption {
      type = lib.types.listOf types.ldap-service;
      default = [ ];
    };
  };

  config =
    let
      services = [
        {
          name = "authelia";
          password = cfg.ldap.secret.authelia-password;
        }
      ]
      ++ cfg.ldap.kanidm.services;

      certDir = "/var/lib/kanidm";
    in
    lib.mkIf (cfg.ldap.enable && cfg.ldap.backend == "kanidm") {
      age.secrets = (
        builtins.listToAttrs (
          builtins.map (s: {
            name = "kanidm-service-${s.name}-password";
            value = {
              file =
                if (lib.isStorePath s.password) then s.password else cfg.secret.directory + ("/" + s.password);
              owner = "authelia-main";
              group = "authelia-main";
            };
          }) services
        )
      );

      services.kanidm = {
        package = kanidm-package;

        server = {
          enable = true;

          settings = {
            origin = mkUrl cfg.ldap.url.proto cfg.ldap.url.name;
            domain = "${cfg.url.domain}";
            bindaddress = "0.0.0.0:${toString cfg.ldap.ports.http}";
            ldapbindaddress = "0.0.0.0:${toString cfg.ldap.ports.ldap}";

            tls_chain = "${certDir}/cert.pem";
            tls_key = "${certDir}/key.pem";
          };
        };

        provision = {
          enable = true;

          # Admin user is created automatically

          # Declarative groups
          groups = {
            services = { };
            admins = { };
            users = { };
          };

          # Declarative users
          persons = lib.mkMerge [
            {
              jacek = {
                displayName = "Jacek";
                #mailAddresses = [ ];
                groups = [
                  "admins"
                  "users"
                ];
              };
            }
            (builtins.listToAttrs (
              builtins.map (s: {
                name = "${s.name}";
                value = {
                  displayName = "${s.name}";
                  groups = [
                    "services"
                  ];
                };
              }) services
            ))
          ];

          systems.oauth2 = { };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${certDir} 0750 0 0"
      ];

      system.activationScripts.generateSSLCert = ''
        if [ ! -f ${certDir}/cert.pem ]; then
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
            -keyout ${certDir}/key.pem \
            -out ${certDir}/cert.pem \
            -days 3650 -nodes \
            -subj "/CN=localhost"

            chmod -R 750 "${certDir}"
        fi
      '';

      systemd.services.kanidm = {
        after = [ "generateSSLCert.service" ];
        wants = [ "generateSSLCert.service" ];
      };

      systemd.services.kanidm-provision.postStart = builtins.concatStringsSep "\n" (
        builtins.map (s: ''
          ${kanidm-package}/bin/kanidm person credential update ${s.name} \
            --password "$(cat ${config.age.secrets."kanidm-service-${s.name}-password".path})" \
            || true
        '') services
      );
    };
}
