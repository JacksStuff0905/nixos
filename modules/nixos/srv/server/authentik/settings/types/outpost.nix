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

      standalone = {
        enable = mkEnableOption "standalone systemd service for this outpost";

        tokenFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to file containing the outpost API token.
            This same token will be injected into authentik via blueprint.
          '';
        };

        tokenEnvVar = mkOption {
          type = types.str;
          default = "";
          description = "Environment variable name for blueprint substitution";
          internal = true;
        };

        listen = {
          http = mkOption {
            type = types.port;
            default = 9000;
            description = "HTTP listen port";
          };

          https = mkOption {
            type = types.port;
            default = 9443;
            description = "HTTPS listen port";
          };

          ldap = mkOption {
            type = types.port;
            default = 3389;
            description = "LDAP listen port (for LDAP outposts)";
          };

          ldaps = mkOption {
            type = types.port;
            default = 6636;
            description = "LDAPS listen port (for LDAP outposts)";
          };

          radius = mkOption {
            type = types.port;
            default = 1812;
            description = "RADIUS listen port (for RADIUS outposts)";
          };

          metrics = mkOption {
            type = types.port;
            default = 9300;
            description = "Metrics listen port";
          };
        };

        extraEnvironment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment variables for the outpost service";
        };
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
