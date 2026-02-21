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
    networking.hostName = "ct-calibre";

    # Services
    srv.server = {
      calibre = {
        enable = true;
        library = "${library-path}";
        authentik = {
          enable = true;
          mode = "proxy";
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
