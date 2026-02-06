{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.launchers.games.steam;
in
{
  options.apps.launchers.games.steam = {
    enable = lib.mkEnableOption "Enable steam module";
  };

  config = lib.mkIf config.apps.launchers.games.steam.enable {
    home.packages = [
      pkgs.steam
    ];
  };
}
