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

  types = {
    host = lib.types.submodule {
      options = with lib.types; {
        src = lib.mkOption { type = str; };
        dest = lib.mkOption { type = str; };

        authelia = lib.mkEnableOption "authelia middleware";
      };
    };
  };
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    hosts = lib.mkOption {
      type = lib.types.listOf types.host;
      default = { };
    };

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

    self = {
      enable = lib.mkEnableOption "self host record";
      url = lib.mkOption {
        type = lib.types.str;
      };
      ip = lib.mkOption {
        type = lib.types.str;
      };
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

      #static.settings = {
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
            transport.respondingTimeouts = {
              readTimeout = 0; # No timeout
              writeTimeout = 0; # No timeout
              idleTimeout = "300s"; # 5 min idle before disconnect
            };
          };
        };

        serversTransport.insecureSkipVerify = true;

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

      #dynamic.dir = "/var/lib/traefik/dynamic";
      #dynamic.files."main" = {
      #settings = {
      dynamicConfigOptions = {
        http = lib.mkMerge [
          cfg.http
          {
            middlewares = {
              authelia-proxy =
                let
                  autheliaUrl = "http://${cfg.authelia.url.ip}:${toString cfg.authelia.url.auth-port}";
                in
                {
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
            routers =
              let
                authHost = "${cfg.authelia.url.name}.${cfg.authelia.url.domain}";
                userHost = "${cfg.authelia.url.lldap-name}.${cfg.authelia.url.domain}";
              in
              {
                auth-srv = {
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
          (lib.mkIf cfg.self.enable {
            routers.self-srv = {
              rule = "Host(`${cfg.self.url}`)";
              service = "self-service";
              tls = { };
            };

            services.self-service.loadBalancer.servers = [
              {
                url = "http://${cfg.self.ip}:8080";
              }
            ];
          })
          ({
            routers = builtins.listToAttrs (
              builtins.map (host: {
                name = (lib.replaceStrings [ "." ] [ "-" ] host.src) + "-srv";
                value = {
                  rule = "Host(`${host.src}`)";
                  service = (lib.replaceStrings [ "." ] [ "-" ] host.src) + "-service";
                  entryPoints = [ "websecure" ];
                  middlewares = if host.authelia then [ "authelia-proxy" ] else [ ];
                  tls = { };
                };
              }) cfg.hosts
            );

            services = builtins.listToAttrs (
              builtins.map (host: {
                name = (lib.replaceStrings [ "." ] [ "-" ] host.src) + "-service";
                value = {
                  loadBalancer = {
                    servers = [
                      {
                        url = "${host.dest}";
                      }
                    ];
                  };
                };
              }) cfg.hosts
            );
          })
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
      #};
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [
      8080
      80
      443
    ];
  };
}
