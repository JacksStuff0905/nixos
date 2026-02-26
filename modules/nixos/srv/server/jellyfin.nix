{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "jellyfin";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
