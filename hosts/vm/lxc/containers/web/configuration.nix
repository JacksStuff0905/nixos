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
    networking.hostName = "ct-web";

    # Services
    srv.server = {
      nginx = {
        enable = true;
        virtualHosts."home.srv.lan" = {
          root = "/var/www/home.srv.lan";
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
