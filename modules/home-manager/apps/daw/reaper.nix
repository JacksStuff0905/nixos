{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.apps.daw.reaper;
in
{
  options.apps.daw.reaper = {
    enable = lib.mkEnableOption "Enable Reaper module";
  };

  config.home.packages = lib.mkIf cfg.enable [
    pkgs.reaper
  ];
}
