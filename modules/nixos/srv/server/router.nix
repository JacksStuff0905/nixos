{
  config,
  lib,
  pkgs,
  util,
  common,
  ...
}:
let
  cfg = config.srv.server.router;

  separateCIDR =
    cidr:
    let
      split = builtins.split "\/" cidr;
      ip = builtins.elemAt split 0;
      mask = lib.toIntBase10 (builtins.elemAt split 2);
    in
    {
      inherit ip mask;
    };
in
{
  options.srv.server.router = {
    enable = lib.mkEnableOption "router";

    firewall = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    nat = {
      enable = lib.mkEnableOption "nat";
      skipPrivate = lib.mkEnableOption "don't nat private ip addresses";
    };

    wan = {
      interface = lib.mkOption {
        type = lib.types.str;
      };

      dhcp = {
        client = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      address = lib.mkOption {
        type = util.types.cidr;
      };
    };

    lan = {
      bridge = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "lanbr";
        };
        interfaces = lib.mkOption {
          type = lib.types.listOf lib.types.str;
        };
      };

      address = lib.mkOption {
        type = util.types.cidr;
        default = config.host.networking.ip;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    services.resolved = {
      enable = false;
    };

    # Configure network interfaces
    networking = {
      # Disable NetworkManager for manual configuration
      networkmanager.enable = false;
      useDHCP = false;

      bridges = {
        "${cfg.lan.bridge.name}" = {
          interfaces = cfg.lan.bridge.interfaces;
        };
      };

      # WAN interface (adjust interface name as needed)
      interfaces."${cfg.wan.interface}" =
        if cfg.wan.dhcp.client then
          {
            useDHCP = true;
          }
        else
          {
            ipv4.addresses = [
              (
                let
                  split = separateCIDR cfg.wan.address;
                in
                {
                  address = split.ip;
                  prefixLength = split.mask;
                }
              )
            ];
          };

      # LAN bridge
      interfaces."${cfg.lan.bridge.name}" = {
        useDHCP = false;

        ipv4.addresses = [
          (
            let
              split = separateCIDR cfg.lan.address;
            in
            {
              address = split.ip;
              prefixLength = split.mask;
            }
          )
        ];
      };

      # NAT for internet sharing
      nat = {
        enable = cfg.nat.enable;
        externalInterface = "${cfg.wan.interface}"; # WAN
        internalInterfaces = [ cfg.lan.bridge.name ]; # LAN
        extraCommands = let
            subnet = util.tools.ip-nix.getSubnet cfg.lan.address;
            lanaddr = "${util.tools.ip-nix.prettyIp subnet.baseIp}/${toString subnet.cidr}";
          in lib.mkIf (cfg.nat.enable && cfg.nat.skipPrivate) ''
          iptables -t nat -A POSTROUTING -s ${builtins.trace lanaddr lanaddr} -d 10.0.0.0/8     -j ACCEPT
          iptables -t nat -A POSTROUTING -s ${lanaddr} -d 172.16.0.0/12  -j ACCEPT
          iptables -t nat -A POSTROUTING -s ${lanaddr} -d 192.168.0.0/16 -j ACCEPT
          iptables -t nat -A POSTROUTING -s ${lanaddr} -o eth0 -j MASQUERADE
        '';
      };

      resolvconf.enable = true;

      useNetworkd = lib.mkForce false;
      dhcpcd = lib.mkIf cfg.wan.dhcp.client {
        enable = true;
        allowInterfaces = [ "${cfg.wan.interface}" ];
      };

      # Simple firewall rules
      firewall = lib.mkMerge [
        {
          enable = true;

          # Allow SSH from LAN only
          /*
            extraCommands = ''
              iptables -A nixos-fw -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
            '';
          */

          allowedUDPPorts = [
            53
            67
          ];
          allowedTCPPorts = [ 53 ];

          extraCommands = ''
            iptables -A FORWARD -i ${cfg.lan.bridge.name} -o ${cfg.wan.interface} -j ACCEPT
            iptables -A FORWARD -i ${cfg.wan.interface} -o ${cfg.lan.bridge.name} -j ACCEPT
          '';
        }
        cfg.firewall
      ];
    };

  };
}
