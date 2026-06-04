{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.apps.browsers.chromium;
in
{
  options.apps.browsers.chromium = {
    enable = lib.mkEnableOption "Enable chromium module";
  };

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
    };
  };
}
