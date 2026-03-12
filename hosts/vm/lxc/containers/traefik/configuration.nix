{
  config,
  pkgs,
  inputs,
  ...
}:
let
  selfIP = "192.168.10.9";
  autheliaIP = "192.168.10.7";
  proxmoxIP = "192.168.8.11";
  routerIP = "192.168.10.1";
  filebrowserIP = "192.168.10.13";
  calibreIP = "192.168.10.12";
  immichIP = "192.168.10.13";
  nasIP = "192.168.10.6";
  dnsIP = "192.168.10.5";
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
      self = {
        enable = true;
        url = "proxy.srv.lan";
        ip = "${selfIP}";
      };

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

      hosts = [
        {
          src = "pve.srv.lan";
          dest = "https://${proxmoxIP}:8006";
        }
        {
          src = "router.srv.lan";
          dest = "https://${routerIP}:443";
        }
        {
          src = "nas.srv.lan";
          dest = "http://${nasIP}:80";
        }
        {
          src = "dns.srv.lan";
          dest = "http://${dnsIP}:80";
        }
        {
          src = "drive.srv.lan";
          dest = "http://${filebrowserIP}:80";
          authelia = true;
        }
        {
          src = "calibre.srv.lan";
          dest = "http://${calibreIP}:8083";
          authelia = true;
        }
        {
          src = "photos.srv.lan";
          dest = "http://${immichIP}:2283";
          authelia = true;
        }
      ];
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
