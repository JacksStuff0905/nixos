{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.other.apps.steam;
in
{
  options.other.apps.steam = {
    enable = lib.mkEnableOption "Enable steam module";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
    };
  };
}
