{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "traefik";

  cfg = config.srv.server."${name}";

  mkCert = domain: ''
    CERT_DIR="/var/lib/traefik/certs"
    if [ ! -f "$CERT_DIR/${domain}/key" ]; then
      mkdir -p "$CERT_DIR"
      ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/${domain}/key" \
        -out "$CERT_DIR/${domain}/crt" \
        -subj "/CN=*.${domain}" \
        -addext "subjectAltName=DNS:*.${domain},DNS:${domain}"
      chmod 600 "$CERT_DIR"/*.key
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
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.generateSSLCerts = builtins.concatStringsSep "\n" (
      builtins.map mkCert cfg.certificates
    );

    services.traefik = {
      enable = true;

      staticConfigOptions = {
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

      dynamicConfigOptions = {
        http = cfg.http;
        https = cfg.https;

        tls = {
          certificates = [
            {
              certFile = "/var/lib/traefik/certs/srv.lan/crt";
              keyFile = "/var/lib/traefik/certs/srv.lan/key";
            }
          ];
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
