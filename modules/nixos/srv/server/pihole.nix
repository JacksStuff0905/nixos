{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "pihole";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";

    domain = lib.mkOption {
      type = lib.types.str;
    };

    upstreams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "8.8.8.8" ];
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "{name = ip;}";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /run/pihole 0755 pihole pihole -"
    ];

    services.resolved.enable = false;

    services.pihole-ftl = {
      enable = true;
      useDnsmasqConfig = true;
      openFirewallDNS = true;
      settings = {
        dns.upstreams = cfg.upstreams;
        dns.listeningMode = "ALL";
      };
    };

    services.dnsmasq =
      let
        address = builtins.map (h: "/${h.name}.${cfg.domain}/${h.value}") (lib.attrsToList cfg.hosts);
      in
      {
        enable = false;

        settings = {
          /*
            server = [
              "/home.lab/192.168.1.1"
              "/internal.corp/10.0.0.53#5353"
            ];
          */

          address = address;

          /*
            rebind-domain-ok = [
              "/home.lab/"
            ];
          */
        };
      };
  };
}
