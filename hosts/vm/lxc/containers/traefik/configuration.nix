{
  config,
  pkgs,
  inputs,
  ...
}:
let
  autheliaIP = "192.168.10.7";
  filebrowserIP = "192.168.10.13";
  calibreIP = "192.168.10.12";
  immichIP = "192.168.10.13";
in
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    networking.hostName = "ct-traefik";

    srv.server.traefik = {
      enable = true;
      authelia = {
        enable = true;
        url = {
          ip = autheliaIP;
          name = "auth";
          lldap-name = "users";
          domain = "srv.lan";
          auth-port = 9091;
          lldap-port = 17170;
        };
      };

      certificates = {
        extra = [
          "lan"
        ];
      };

      http = {
        routers = {
          filebrowser-srv = {
            rule = "Host(`drive.srv.lan`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia" ];
            service = "filebrowser-service";
            tls = { };
          };

          calibre-srv = {
            rule = "Host(`calibre.srv.lan`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia" ];
            service = "calibre-service";
            tls = { };
          };

          immich-srv = {
            rule = "Host(`photos.srv.lan`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia" ];
            service = "immich-service";
            tls = { };
          };
        };

        services = {
          filebrowser-service = {
            loadBalancer = {
              servers = [
                { url = "http://${filebrowserIP}:80"; }
              ];
            };
          };

          calibre-service = {
            loadBalancer = {
              servers = [
                { url = "http://${calibreIP}:8083"; }
              ];
            };
          };

          immich-service = {
            loadBalancer = {
              servers = [
                { url = "http://${immichIP}:2283"; }
              ];
            };
          };
        };
      };

      /*
        virtualHosts = {
          "browse.srv.lan" = {
            serverAliases = [ "drive.srv.lan" ];

            #enableACME = true;
            forceSSL = true;

            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";

            locations."/" = {
              proxyPass = "http://192.168.10.13:30051";
              proxyWebsockets = true;

              extraConfig =
                ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                '';
            };

            # Authentik outpost endpoints
            locations."/outpost.goauthentik.io" = {
              proxyPass = "http://192.168.10.7:9000/outpost.goauthentik.io";
              extraConfig = ''
                proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
                add_header Set-Cookie $auth_cookie;
                auth_request_set $auth_cookie $upstream_http_set_cookie;
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
              '';
            };

            # Redirect to Authentik login when not authenticated
            locations."@goauthentik_proxy_signin" = {
              extraConfig = ''
                internal;
                add_header Set-Cookie $auth_cookie;
                return 302 /outpost.goauthentik.io/start?rd=$request_uri;
              '';
            };
          };

          "auth.srv.lan" = {
            serverAliases = [ "login.srv.lan" ];
            forceSSL = true;
            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";
            locations."/" = {
              proxyPass = "http://192.168.10.7:9000";
              proxyWebsockets = true;
            };
          };

          "test.srv.lan" = {
            locations."/" = {
              proxyPass = "http://192.168.10.9:880";
            };
          };

          "home.srv.lan" = {
            forceSSL = true;
            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";
            locations."/" = {
              proxyPass = "http://192.168.10.9:880";
              proxyWebsockets = true;
            };
            locations."/develop/" = {
              proxyPass = "http://192.168.10.9:7681/";
              proxyWebsockets = true;
            };
          };

          "dns.srv.lan" = {
            forceSSL = true;
            http2 = true;
            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";
            locations."= /" = {
              return = "301 https://$host/admin";
            };

            locations."/" = {
              proxyPass = "http://192.168.10.5:80";
            };
          };

          "router.srv.lan" = {
            forceSSL = true;
            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";
            locations."/" = {
              proxyPass = "https://192.168.10.1:443";
              proxyWebsockets = true;
            };
          };

          "nas.srv.lan" = {
            forceSSL = true;
            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";
            locations."/" = {
              proxyPass = "https://192.168.10.6:443";
              proxyWebsockets = true;
            };
          };

          "calibre.srv.lan" = {
            forceSSL = true;
            http2 = true;
            sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
            sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";

            extraConfig = ''
              proxy_read_timeout 1200s;
              proxy_send_timeout 1200s;
              proxy_buffer_size 128k;
              proxy_buffers 4 256k;
              proxy_busy_buffers_size 256k;
            '';

            locations."/" = {
              proxyPass = "http://192.168.10.12:8083";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header X-Forwarded-Proto https;
                proxy_set_header X-Scheme https;
              '';
            };

            locations."/manage/" = {
              proxyPass = "https://192.168.10.9:8181/";
              proxyWebsockets = true;
            };
          };
        };
      */
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
