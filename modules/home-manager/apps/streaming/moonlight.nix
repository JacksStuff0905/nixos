{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.streaming.moonlight;
in
{
  options.apps.streaming.moonlight = {
    enable = lib.mkEnableOption "moonlight";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      moonlight
    ];
  };
}
