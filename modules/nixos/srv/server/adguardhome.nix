{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "adguardhome";

  cfg = config.srv.server."${name}";

  hagezi-levels = {
    light = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/light.txt";
    normal = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/multi.txt";
    pro = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
    pro-plus = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.plus.txt";
  };
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

    lists = {
      stevenBlack.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      hagezi = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };

        level = lib.mkOption {
          type = lib.types.enum (builtins.attrNames hagezi-levels);
          default = "pro";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.resolved.enable = false;

    networking.firewall.allowedUDPPorts = [ 53 ];

    services.adguardhome = {
      enable = true;
      host = "0.0.0.0";
      port = 80;
      openFirewall = true;
      mutableSettings = false;

      settings = {
        schema_version = 20;

        http = {
          address = "0.0.0.0:3000";
        };

        dns = {
          bootstrap_dns = [
            "9.9.9.9"
            "1.1.1.1"
          ];

          rewrites = lib.mapAttrsToList (name: value: {
            domain = "${name}.${cfg.domain}";
            answer = "${value}";
          }) cfg.hosts;

          upstream_dns = cfg.upstreams;
          #"127.0.0.1:5335"
          #"8.8.8.8"
          # Uncomment the following to use a local DNS service (e.g. Unbound)
          # Additionally replace the address & port as needed
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;

          parental_enabled = false; # Parental control-based DNS requests filtering.
          safe_search = {
            enabled = false; # Enforcing "Safe search" option for search engines, when possible.
          };
        };
        # The following notation uses map
        # to not have to manually create {enabled = true; url = "";} for every filter
        # This is, however, fully optional
        filters =
          map
            (url: {
              enabled = true;
              url = url;
            })
            [
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
              (lib.mkIf cfg.lists.stevenBlack.enable "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts")
              (lib.mkIf cfg.lists.hagezi.enable "${hagezi-levels."${cfg.lists.hagezi.level}"}")
            ];
      };
    };
  };
}
