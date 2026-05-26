{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.launchers.games.heroic;
in
{
  options.apps.launchers.games.heroic = {
    enable = lib.mkEnableOption "Enable heroic module";
  };

  config = lib.mkIf config.apps.launchers.games.heroic.enable {
    home.packages = [
      pkgs.heroic
    ];
  };
}
