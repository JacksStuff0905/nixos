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
      samba = {
        enable = true;
        ldapUser = "calibre";
        domain = "srv.lan";
        ldapHost = "192.168.10.7";
        secret = {
          ldap-password = ../../../../../secrets/ldap-users/calibre-service-password.age;
        };

        shares = {
          library = {
            comment = "Calibre library";
            path = "${library-path}";
            browseable = "no";
            "read only" = "yes";
            "valid users" = "@netadmins";
            "create mask" = "0700";
            "directory mask" = "0700";
          };
        };
      };
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
