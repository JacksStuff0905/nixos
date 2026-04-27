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
    # Services
    srv.server = {
      adguardhome = {
        enable = true;
        domain = "lan";
        upstreams = [
          #"192.168.8.1"
          "8.8.8.8"
        ];

        hosts = {
          "*.srv" = "192.168.10.9";
        };

        lists = {
          hagezi.level = "pro-plus";
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
