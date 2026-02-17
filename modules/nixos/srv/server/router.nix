{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.srv.server.router;

  types = {
    # Validate CIDR
    cidr =
      lib.types.addCheck lib.types.str (
        s: builtins.match "^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$" s != null
      )
      // {
        description = "IP address with mask (e.g., 192.168.1.1/24)";
      };

    ip =
      lib.types.addCheck lib.types.str (
        s: builtins.match "^([0-9]{1,3}\\.){3}[0-9]{1,3}$" s != null
      )
      // {
        description = "IP address without mask (e.g., 192.168.1.1)";
      };

    ipRange = lib.types.submodule {
      options = {
        start = lib.mkOption { type = types.ip; };
        end = lib.mkOption { type = types.ip; };
      };
    };

    interface = lib.types.submodule {
      options = with lib.types; {
        name = lib.mkOption { type = str; };

        dhcp = {
          client = lib.mkOption {
            type = bool;
            default = false;
          };
          server = {
            enable = lib.mkOption {
              type = bool;
              default = false;
            };

            range = lib.mkOption {
              type = types.ipRange;
            };

            duration = lib.mkOption {
              type = str;
              default = "6h";
            };
          };
        };

        dns = {
          enable = lib.mkEnableOption "dns";
          port = lib.mkOption {
            type = port;
            default = 53;
          };
          servers = lib.mkOption {
            type = listOf types.ip;
            default = [ "8.8.8.8" ];
          };
        };

        address = {
          enable = lib.mkEnableOption "ipv4 address";
          cidr = lib.mkOption { type = types.cidr; };
        };
      };
    };
  };

  mapInterfaces = builtins.listToAttrs (
    func:
    (builtins.map func (
      [
        cfg.interfaces.lan
        cfg.interfaces.wan
      ]
      ++ cfg.interfaces.extra
    ))
  );
in
{
  options.srv.server.router = {
    enable = lib.mkEnableOption "router";

    interfaces = {
      wan = lib.mkOption {
        type = types.interface;
      };

      lan = lib.mkOption {
        type = types.interface;
      };

      extra = lib.mkOption {
        type = lib.types.listOf types.interface;
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = false;
      useDHCP = false;

      # Interface config
      interfaces = mapInterfaces (i: {
        name = i.name;
        value = {
          useDHCP = i.dhcp.client;
          ipv4.addresses =
            if i.address.enable then
              (
                let
                  parts = lib.splitString "/" i.address.cidr;
                in
                [
                  {
                    address = lib.head parts;
                    prefixLength = lib.toInt (lib.last parts);
                  }
                ]
              )
            else
              [ ];
        };
      });

      # NAT for internet sharing
      /*
        nat = {
          enable = true;
          externalInterface = cfg.interfaces.wan.name; # WAN
          internalInterfaces = [
            cfg.interfaces.lan.name
          ]
          ++ (builtins.map (f: f.name) cfg.interfaces.extra); # LAN
        };
      */

      # Simple firewall rules
      /*
        firewall = {
          enable = true;

          # Allow SSH from LAN only
          extraCommands = ''
            iptables -A nixos-fw -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
          '';
        };
      */
    };

    # DHCP and DNS server (dnsmasq provides both)
    services.dnsmasq.enable = false;

    # Define dnsmasq instances
    systemd.services = mapInterfaces (
      i:
      lib.mkIf (i.dhcp.server.enable || i.dns.enable) {
        name = "dnsmasq-${i.name}";
        value = {
          description = "Dnsmasq for eth0";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.dnsmasq} -k --conf-file=/etc/dnsmasq-${i.name}.conf";
            Restart = "always";
          };
        };
      }
    );

    # Write the config files manually
    # TODO: add conditonal config for dns and dhcp
    environment.etc = mapInterfaces (i: {
      name = "dnsmasq-${i.name}.conf";
      value = {
        text = ''
        ''

        + (if i.dhcp.server.enable then ''
          interface=${i.name}
          dhcp-range=${i.dhcp.server.range.start},${i.dhcp.server.range.end},${i.dhcp.server.duration}
        '' else "")

        + (if i.dns.enable then ''
          listen-address=${i.address.cidr}
          bind-interfaces
          port=${i.dns.port}
        '' + (lib.concatMapStringsSep "\n" (s: "server=${s}") cfg.dns.servers) else "");
      };
    });

    /*
      services.dnsmasq = {
        enable = true;
        settings = {
          # DHCP Configuration
          dhcp-range = [ "192.168.1.100,192.168.1.200,12h" ];
          interface = cfg.interfaces.lan;

          # DNS Configuration
          server = [
            "8.8.8.8"
            "8.8.4.4"
          ]; # Upstream DNS servers

          # Don't use /etc/hosts
          no-hosts = true;

          # DHCP Options
          dhcp-option = [
            "option:router,192.168.1.1"
            "option:dns-server,192.168.1.1" # Use router as DNS server
          ];
        };
      };
    */
  };
}
