{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "immich";

  cfg = config.srv.server."${name}";

in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    port = lib.mkOption {
      type = lib.types.int;
      default = 2283;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich = {
      enable = true;
      port = cfg.port;
      host = "0.0.0.0";
      openFirewall = cfg.openFirewall;
    };
  };
}
