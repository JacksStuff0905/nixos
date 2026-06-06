{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  name = "nixflix";

  cfg = config.srv.server."${name}";

  generatedSecrets = [
    "jellyfin-api-key"
    "sonarr-api-key"
    "radarr-api-key"
    "prowlarr-api-key"
  ];

  manualSecrets = [
    "sonarr-password"
    "radarr-password"
    "prowlarr-password"
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
      }) generatedSecrets
      ++ builtins.map (s: {
        name = "${s}";
        value = {
          rekeyFile = cfg.secretsDir + "/${s}.age";
        };
      }) manualSecrets
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

      sonarr = {
        enable = true;
        config = {
          apiKey._secret = config.age.secrets.sonarr-api-key.path;
          hostConfig = {
            username = "admin";
            password._secret = config.age.secrets.sonarr-password.path;
          };
        };
      };

      radarr = {
        enable = true;
        config = {
          apiKey = {
            _secret = config.age.secrets.radarr-api-key.path;
          };
          hostConfig = {
            username = "admin";
            password._secret = config.age.secrets.radarr-password.path;
          };
        };
      };

      prowlarr = {
        enable = true;
        config = {
          apiKey = {
            _secret = config.age.secrets.prowlarr-api-key.path;
          };
          hostConfig = {
            username = "admin";
            password._secret = config.age.secrets.prowlarr-password.path;
          };
        };
      };

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

    services.nginx.defaultListenAddresses = [ "0.0.0.0" ];
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
