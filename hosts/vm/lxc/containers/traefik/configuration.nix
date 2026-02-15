{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    networking.hostName = "ct-traefik";

    srv.server.traefik = {
      enable = true;
      authentik = {
        enable = true;
        url = "https://192.168.10.7:9443";
        domain = "srv.lan";
      };

      certificates = [
        "srv.lan"
        "lan"
      ];

      http = {
        routers = {
          browse-srv = {
            rule = "Host(`browse.srv.lan`) || Host(`drive.srv.lan`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authentik" ];
            service = "browse-service";
            tls = { };
          };
        };

        services = {
          browse-service = {
            loadBalancer = {
              servers = [
                { url = "http://192.168.10.13:30051"; }
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
