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
      keepalived = {
        enable = true;
        vrrpId = 1;
        master.enable = true;
        interface = "eth0";
        vip = "192.168.10.5/24";
        script = ''
          ${pkgs.dig}/bin/dig @127.0.0.1 google.com +short +time=2 +tries=1 > /dev/null 2>&1
        '';
      };

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
