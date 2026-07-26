{
  config,
  pkgs,
  lib,
  util,
  common,
  ...
}:
let
  cfg = config.srv.server.dhcp;
in
{
  options.srv.server.dhcp = {
    enable = lib.mkEnableOption "dhcp";

    interface = lib.mkOption {
      type = lib.types.str;
    };

    range =
      with util.tools.ip-nix;
      let
        from = (parseSubnet (getSubnet "${config.host.networking.ip}")).range.from;
        to = (parseSubnet (getSubnet "${config.host.networking.ip}")).range.to;
        start = zipIps (a: b: builtins.floor (util.tools.lerp a b 0.25)) from to;
        end = zipIps (a: b: a - b) to [
          0
          0
          0
          1
        ];
      in
      {
        start = lib.mkOption {
          type = util.types.ip;
          default = prettyIp start;
        };
        end = lib.mkOption {
          type = util.types.ip;
          default = prettyIp end;
        };
        time = lib.mkOption {
          type = lib.types.str;
          default = "12h";
        };
      };

    options = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };
  config = {
    services.dnsmasq = {
      enable = cfg.enable;
      resolveLocalQueries = true;

      settings = {
        # DHCP Configuration
        dhcp-range = [
          "${cfg.range.start},${cfg.range.end},${cfg.range.time}"
        ];
        interface = [
          "${cfg.interface}"
          "lo"
        ];

        dhcp-host =
          builtins.map (h: "${h.host.networking.mac},${(util.tools.ip-nix.splitIp h.host.networking.ip).ip}")
            (
              builtins.filter (
                h:
                (h.host.networking.mac or null) != null
                && (h.host.networking.ip or null) != null
                &&
                  (util.tools.ip-nix.getSubnet h.host.networking.ip).baseIp
                  == (util.tools.ip-nix.getSubnet config.host.networking.ip).baseIp
              ) (builtins.attrValues common.hosts)
            );

        # Don't use /etc/hosts
        no-hosts = true;

        # DHCP Options
        dhcp-option =
          let
            mkOption = options: lib.mapAttrsToList (o: v: "option:${o},${v}") options;

            ip = (util.tools.ip-nix.splitIp config.host.networking.ip).ip;
          in
          (lib.mkMerge [
            (mkOption ({
              "router" = "${ip}";
              "dns-server" = "${ip}";
            }))
            (mkOption cfg.options)
          ]);
      };
    };
  };
}
