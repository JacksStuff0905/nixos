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
      openFirewallWebserver = true;

      lists = [
        {
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          type = "block";
          enabled = true;
          description = "Steven Black's HOSTS";
        }
        {
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/light.txt";
          type = "block";
          enabled = true;
        }
      ];

      settings = {
        dns.upstreams = cfg.upstreams;
        dns.listeningMode = "ALL";

        webserver = {
          api = {
            password = "2cbd419e404487682a6456daa385f1d247da6dc54237379938ddc48b8f269962";
          };
          session = {
            timeout = 43200; # 12h
          };
        };
      };

    };

    services.pihole-web = {
      enable = true;
      ports = [ 80 ];
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
