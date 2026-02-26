{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.srv.server.authentik;

  outpostBinaries = {
    proxy = "${cfg.package}/bin/ak-outpost-proxy";
    ldap = "${cfg.package}/bin/ak-outpost-ldap";
    radius = "${cfg.package}/bin/ak-outpost-radius";
    rac = "${cfg.package}/bin/ak-outpost-rac";
  };
in
{
  options.srv.server.authentik.deploy = {
    enable = mkEnableOption "automatic blueprint deployment";
  };

  config = mkIf (cfg.enable && cfg.deploy.enable) {
    systemd.services.authentik-worker = {
      environment = {
        AUTHENTIK_BLUEPRINTS_DIR = cfg.generatedPath;
      };

      serviceConfig = {
        EnvironmentFile = config.age.secrets.oauth2-secret.path;
      };
    };

    systemd.services.authentik = {
      environment = lib.mkMerge [
        {
          AUTHENTIK_BLUEPRINTS_DIR = cfg.generatedPath;
        }
      ];

      serviceConfig = {
        EnvironmentFile = config.age.secrets.oauth2-secret.path;
      };
    };

    services.authentik.settings.blueprints_dir = cfg.generatedPath;
  };
}
