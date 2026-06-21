{
  config,
  lib,
  pkgs,
  common,
  util,
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

  httpServices =
    lib.mapAttrsToList
      (n: s: {
        src = "${n}\\.${
          builtins.replaceStrings [ "." ] [ "\\." ] (s.domain or config.host.networking.domain)
        }";
        dest = "${
          if
            (builtins.elem s.proto [
              "http"
              "https"
            ])
          then
            "${s.proto}://"
          else
            ""
        }${s.ip or config.host.networking.ip}:${toString s.port}";
        middleware = if (s.middleware.enable or false) then s.middleware.extraConfig or { } else null;
        middlewares = s.middlewares;
      })
      (
        lib.filterAttrs (
          n: s:
          builtins.elem s.proto [
            "http"
            "https"
          ]
        ) ((util.tools.getHostServices common.hosts) // cfg.extraServices)
      );

  tcpServices =
    lib.mapAttrsToList
      (n: s: {
        src = "${n}\\.${
          builtins.replaceStrings [ "." ] [ "\\." ] (s.domain or config.host.networking.domain)
        }";
        dest = "${s.ip or config.host.networking.ip}:${toString s.port}";
        middleware = if (s.middleware.enable or false) then s.middleware.extraConfig or { } else null;
        middlewares = s.middlewares;
      })
      (
        lib.filterAttrs (
          n: s:
          builtins.elem s.proto [
            "tcp"
            "tcp/udp"
          ]
        ) ((util.tools.getHostServices common.hosts) // cfg.extraServices)
      );

  mkServiceName = s: (lib.replaceStrings [ "\\." "." ] [ "-" "-" ] s);

  certificates = cfg.certificates.extra ++ [ cfg.certificates.default ];
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
    certificates = {
      default = lib.mkOption {
        type = lib.types.str;
        default = "lan";
      };
      extra = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };

    extraServices =
      with lib;
      with types;
      mkOption {
        type = attrsOf util.types.publicService;
        default = { };
      };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${certDir} 0750 0 0"
    ];

    system.activationScripts.generateSSLCerts = builtins.concatStringsSep "\n" (
      builtins.map mkCert certificates
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
          ldaps = {
            address = ":636";
          };
        };

        serversTransport.insecureSkipVerify = true;

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log = {
          level = "DEBUG";
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
      dynamicConfigOptions =
        let
          mkServices =
            {
              services,
              hostFunc,
              entryPoints,
              serverVal,
              enableMiddlewares,
            }:
            (lib.mkMerge [
              (lib.mkIf enableMiddlewares {
                middlewares = builtins.listToAttrs (
                  builtins.map (s: {
                    name = "${mkServiceName s.src}";
                    value = s.middleware;
                  }) (builtins.filter (s: s.middleware != null) services)
                );
              })
              {
                routers = builtins.listToAttrs (
                  builtins.map (s: {
                    name = (mkServiceName s.src) + "-srv";
                    value = {
                      rule = hostFunc "${s.src}";
                      service = (mkServiceName s.src) + "-service";
                      entryPoints = entryPoints;
                      middlewares = builtins.map (m: mkServiceName m) s.middlewares;
                      tls = { };
                    };
                  }) services
                );

                services = builtins.listToAttrs (
                  builtins.map (s: {
                    name = (mkServiceName s.src) + "-service";
                    value = {
                      loadBalancer = {
                        servers = [
                          {
                            "${serverVal}" = "${s.dest}";
                          }
                        ];
                      };
                    };
                  }) services
                );
              }
            ]);
        in
        {
          http = lib.mkMerge [
            cfg.http
            (mkServices {
              services = httpServices;
              hostFunc = (src: "HostRegexp(`${src}`)");
              entryPoints = [ "websecure" ];
              serverVal = "url";
              enableMiddlewares = true;
            })
          ];
          https = cfg.https;

          tcp = mkServices {
            services = tcpServices;
            hostFunc = (src: "HostSNI(`${builtins.replaceStrings [ "\\." ] [ "." ] src}`)");
            entryPoints = [
              "ldaps"
            ];
            serverVal = "address";
            enableMiddlewares = false;
          };

          tls = {
            certificates = builtins.map (v: {
              certFile = "${certDir}/${v}/crt";
              keyFile = "${certDir}/${v}/key";
            }) certificates;

            stores.default.defaultCertificate =
              let
                cert = cfg.certificates.default;
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
      636
    ];
  };
}
