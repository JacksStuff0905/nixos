{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "traefik";

  cfg = config.srv.server."${name}";

  certDir = "/var/lib/traefik/certs";

  mkCert = domain: ''
    CERT_DIR="${certDir}/${domain}"
    if [ ! -d "$CERT_DIR" ]; then
      mkdir -p "$CERT_DIR"
      ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/key" \
        -out "$CERT_DIR/crt" \
        -subj "/CN=*.${domain}" \
        -addext "subjectAltName=DNS:*.${domain},DNS:${domain}"
      chmod -R 750 "$CERT_DIR"
    fi
  '';
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    http = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    https = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    certificates.extra = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    authelia = {
      enable = lib.mkEnableOption "Enable authelia integration";
      url = {
        ip = lib.mkOption {
          type = lib.types.str;
        };

        auth-port = lib.mkOption {
          type = lib.types.int;
        };

        lldap-port = lib.mkOption {
          type = lib.types.int;
        };

        name = lib.mkOption {
          type = lib.types.str;
        };

        lldap-name = lib.mkOption {
          type = lib.types.str;
        };

        domain = lib.mkOption {
          type = lib.types.str;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${certDir} 0750 0 0"
    ];

    system.activationScripts.generateSSLCerts = builtins.concatStringsSep "\n" (
      builtins.map mkCert (
        if (cfg.authelia.enable && !(builtins.elem cfg.authelia.url.domain cfg.certificates.extra)) then
          (cfg.certificates.extra ++ [ cfg.authelia.url.domain ])
        else
          cfg.certificates.extra
      )
    );

    systemd.services.traefik = {
      after = [ "generateSSLCerts.service" ];
      wants = [ "generateSSLCerts.service" ];
    };
    services.traefik = {
      enable = true;

      static.settings = {
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
          };
        };

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log = {
          level = "INFO";
          filePath = "${config.services.traefik.dataDir}/traefik.log";
          format = "json";
        };

        /*
          certificatesResolvers.letsencrypt.acme = {
            email = "postmaster@YOUR.DOMAIN";
            storage = "${config.services.traefik.dataDir}/acme.json";
            httpChallenge.entryPoint = "web";
          };
        */

        api.dashboard = true;
        # Access the Traefik dashboard on <Traefik IP>:8080 of your server
        api.insecure = true;
      };

      dynamic.dir = "/var/lib/traefik/dynamic";
      dynamic.files."main" = {
        settings = {
          http = lib.mkMerge [
            cfg.http
            {
              middlewares = {
                authelia = let
                    autheliaUrl = "http://${cfg.authelia.url.ip}:${toString cfg.authelia.url.auth-port}";
                  in {
                  forwardAuth = {
                    address = "${autheliaUrl}/api/authz/forward-auth";
                    trustForwardHeader = true;
                    authResponseHeaders = [
                      "Remote-User"
                      "Remote-Groups"
                      "Remote-Email"
                      "Remote-Name"
                    ];
                  };
                };
              };
              /*
                middlewares = {
                  authelia = {
                    forwardAuth = {
                      tls.insecureSkipVerify = true;
                      address = "${cfg.authelia.url}/outpost.goauthentik.io/auth/traefik";
                      trustForwardHeader = true;
                      authResponseHeaders = [
                        "X-authelia-username"
                        "X-authelia-groups"
                        "X-authelia-email"
                        "X-authelia-name"
                        "X-authelia-uid"
                        "X-authelia-jwt"
                        "X-authelia-meta-jwks"
                        "X-authelia-meta-outpost"
                        "X-authelia-meta-provider"
                        "X-authelia-meta-app"
                        "X-authelia-meta-version"
                      ];
                    };
                  };
                };
              */

              routers =
                let
                  authHost = "${cfg.authelia.url.name}.${cfg.authelia.url.domain}";
                  userHost = "${cfg.authelia.url.lldap-name}.${cfg.authelia.url.domain}";
                in
                {
                  auth-srv = {
                    #entryPoints = [ "websecure" ];
                    # rule = "Host(`auth.${cfg.authelia.domain}`) || HostRegexp(`{subdomain:[a-z0-9]+}.${cfg.authentik.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)";
                    rule = "Host(`${authHost}`)";
                    service = "auth-service";
                    tls = { };
                  };

                  auth-lldap-srv = {
                    rule = "Host(`${userHost}`)";
                    service = "auth-lldap-service";
                    tls = { };
                  };
                };

              services = {
                auth-service.loadBalancer.servers = [
                  {
                    url = "http://${cfg.authelia.url.ip}:${toString cfg.authelia.url.auth-port}";
                  }
                ];

                auth-lldap-service.loadBalancer.servers = [
                  {
                    url = "http://${cfg.authelia.url.ip}:${toString cfg.authelia.url.lldap-port}";
                  }
                ];
              };
            }
          ];
          https = cfg.https;

          tls = {
            certificates = builtins.map (v: {
              certFile = "${certDir}/${v}/crt";
              keyFile = "${certDir}/${v}/key";
            }) cfg.certificates.extra;

            stores.default.defaultCertificate =
              let
                cert = cfg.authelia.url.domain;
              in
              {
                certFile = "${certDir}/${cert}/crt";
                keyFile = "${certDir}/${cert}/key";
              };
          };
        };
      };
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [
      8080
      80
      443
    ];
  };
}
