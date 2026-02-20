{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.srv.server.authentik.deploy;
in
{
  options.srv.server.authentik.deploy = {
    enable = mkEnableOption "automatic blueprint deployment";
  };

  config = mkIf (config.srv.server.authentik.enable && cfg.enable) {
    systemd.services.authentik-worker.environment = {
      AUTHENTIK_BLUEPRINTS_DIR = config.srv.server.authentik.generatedPath;
    };

    systemd.services.authentik.environment = {
      AUTHENTIK_BLUEPRINTS_DIR = config.srv.server.authentik.generatedPath;
    };

    services.authentik.settings.blueprints_dir = config.srv.server.authentik.generatedPath;
  };
}
