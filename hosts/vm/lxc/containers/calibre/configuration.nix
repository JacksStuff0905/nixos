{
  config,
  pkgs,
  inputs,
  ...
}:
let
  library-path = "/var/lib/calibre/books";
in
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    # Services
    srv.server = {
      calibre = {
        enable = true;
        library = "${library-path}";
        auth = {
          enable = true;
          mode = "ldap";
          ldap = {
            host = "192.168.10.7";
            domain = "srv.lan";
            passwordFile = ../../../../../secrets/ldap-users/calibre-service-password.age;
            username = "calibre";
            group = "calibre";
          };
        };
        frontends = {
          calibre-web.enable = false;
          calibre-web-automated.enable = true;
        };
      };
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
