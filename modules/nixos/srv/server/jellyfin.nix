{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  name = "jellyfin";

  cfg = config.srv.server."${name}";

  moviesDir = "/mnt/media/movies";

  apiKeyPath = "/var/lib/jellyfin-api-key";

  secrets = [
    "jellyfin-api-key"
  ];
in
{
  imports = [ inputs.nixflix.nixosModules.default ];

  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "films.srv.lan";
    };

    secretsDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {

    /*
      users.groups.jellyfin = { };

      # Add jellyfin user to video/render groups for HW accel
      users.users.jellyfin = {
        isSystemUser = true;
        group = "jellyfin";
        extraGroups = [
          "video"
          "render"
        ];
      };
    */

    age.secrets = builtins.listToAttrs (
      builtins.map (s: {
        name = "${s}";
        value = {
          rekeyFile = cfg.secretsDir + "/${s}.age";
          generator.script = "hex";
        };
      }) secrets
    );

    nixflix = {
      enable = true;

      mediaDir = "/data/media";

      stateDir = "/data/.state";

      # Reverse proxy: choose one
      nginx = {
        enable = true;
        domain = cfg.domain;
      };

      # caddy.enable = true;

      postgres.enable = true;

      /*
        sonarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."sonarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."sonarr/password".path;
            };
          };
        };
      */

      /*
        radarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."radarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."radarr/password".path;
            };
          };
        };
      */

      /*
        prowlarr = {
          enable = true;
          config = {
            apiKey = {
              _secret = config.sops.secrets."prowlarr/api_key".path;
            };
            hostConfig.password = {
              _secret = config.sops.secrets."prowlarr/password".path;
            };
          };
        };
      */

      /*
        sabnzbd = {
          enable = true;
          settings = {
            misc.api_key = {
              _secret = config.sops.secrets."sabnzbd/api_key".path;
            };
          };
        };
      */

      jellyfin = {
        enable = true;
        apiKey._secret = config.age.secrets.jellyfin-api-key.path;
        users.admin = {
          policy.isAdministrator = true;
          password = {
            _secret = pkgs.writeText "passwordtmp.txt" "abcd123";
          };
        };
        openFirewall = true;
      };
    };
  };
}
