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
    networking.hostName = "ct-pihole";

    # Services
    srv.server = {
      pihole = {
        enable = true;
        domain = "lan";
        upstreams = [
          "192.168.8.1"
          "8.8.8.8"
        ];

        hosts = {
          "srv" = "192.168.10.9";
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
