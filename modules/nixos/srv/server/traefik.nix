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
    mkdir -p "$CERT_DIR"
    if [ ! -f "$CERT_DIR/key" ]; then
      mkdir -p "$CERT_DIR"
      ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/key" \
        -out "$CERT_DIR/crt" \
        -subj "/CN=*.${domain}" \
        -addext "subjectAltName=DNS:*.${domain},DNS:${domain}"
      chmod 700 "$CERT_DIR/key"
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
    certificates = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    authentik = {
      enable = lib.mkEnableOption "Enable authentik integration";
      url = lib.mkOption {
        type = lib.types.str;
      };
      domain = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${certDir} 0600 0 0"
    ];

    system.activationScripts.generateSSLCerts = builtins.concatStringsSep "\n" (
      builtins.map mkCert (
        if (cfg.authentik.enable && !(builtins.elem cfg.authentik.domain cfg.certificates)) then
          (cfg.certificates ++ [ cfg.authentik.domain ])
        else
          cfg.certificates
      )
    );

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

        certificatesResolvers = {
          letsencrypt = {
            acme = {
              email = "admin@example.com";
              storage = "/var/lib/traefik/acme.json";
              httpChallenge = {
                entryPoint = "web";
              };
            };
          };
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
                authentik = {
                  forwardAuth = {
                    tls.insecureSkipVerify = true;
                    address = "${cfg.authentik.url}/outpost.goauthentik.io/auth/traefik";
                    trustForwardHeader = true;
                    authResponseHeaders = [
                      "X-authentik-username"
                      "X-authentik-groups"
                      "X-authentik-email"
                      "X-authentik-name"
                      "X-authentik-uid"
                      "X-authentik-jwt"
                      "X-authentik-meta-jwks"
                      "X-authentik-meta-outpost"
                      "X-authentik-meta-provider"
                      "X-authentik-meta-app"
                      "X-authentik-meta-version"
                    ];
                  };
                };
              };

              routers = {
                auth-srv = {
                  entryPoints = [ "websecure" ];
                  rule = "Host(`auth.${cfg.authentik.domain}`) || HostRegexp(`{subdomain:[a-z0-9]+}.${cfg.authentik.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)";
                  service = "auth-service";
                  tls = { };
                };
              };

              services = {
                auth-service.loadBalancer.servers = [
                  {
                    url = "${cfg.authentik.url}";
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
            }) cfg.certificates;
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
