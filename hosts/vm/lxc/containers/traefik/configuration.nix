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
    age.secrets.ca-key = {
      rekeyFile = ../../ssl/ca-key.age;
      owner = "traefik";
      group = "traefik";
      mode = "0600";
    };

    srv.server.traefik = {
      enable = true;
      certificates.ca = {
        cert = ../../ssl/ca.crt;
        key = config.age.secrets.ca-key.path;
      };
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
