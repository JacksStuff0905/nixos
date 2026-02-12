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
      };
    };
  
    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
