{ lib }:

with lib;

types.submodule (
  { name, ... }:
  {
    options = {
      enable = mkEnableOption "this outpost" // {
        default = true;
      };

      name = mkOption {
        type = types.str;
        default = name;
        description = "Outpost name";
      };

      type = mkOption {
        type = types.enum [
          "proxy"
          "ldap"
          "radius"
          "rac"
        ];
        default = "proxy";
        description = "Outpost type";
      };

      managed = mkOption {
        type = types.bool;
        default = false;
        description = "Use embedded/managed outpost (runs within authentik)";
      };

      config = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Outpost configuration";
        example = {
          authentik_host = "https://auth.example.com";
          authentik_host_insecure = false;
        };
      };

      serviceConnection = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Service connection name (for Docker/Kubernetes managed deployments)";
      };

      applications = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Application slugs to include in this outpost";
      };
    };
  }
)
