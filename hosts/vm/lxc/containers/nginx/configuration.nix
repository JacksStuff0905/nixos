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
    networking.hostName = "ct-nginx";


    srv.server.nginx = {
      enable = true;

      certificates = [
        "srv.lan"
        "lan"
      ];

      virtualHosts = {
        "browse.srv.lan" = {
          serverAliases = [ "drive.srv.lan" ];
          forceSSL = true;
          sslCertificate = "/var/lib/nginx/certs/srv.lan/crt";
          sslCertificateKey = "/var/lib/nginx/certs/srv.lan/key";
          locations."/" = {
            proxyPass = "http://192.168.10.9:30051";
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
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
