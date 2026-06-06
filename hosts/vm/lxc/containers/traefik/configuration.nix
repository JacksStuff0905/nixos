{
  config,
  pkgs,
  inputs,
  ...
}:
let
  selfIP = "192.168.10.9";
in
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    srv.server.traefik = {
      enable = true;
      /*
        hosts = [
          {
            src = "home.srv.lan";
            dest = "http://${webIP}:80";
          }
          {
            src = "dns.srv.lan";
            dest = "http://${dnsIP}:80";
            authelia = true;
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
      */
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
