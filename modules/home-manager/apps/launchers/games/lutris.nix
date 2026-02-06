{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.launchers.games.lutris;
in
{
  options.apps.launchers.games.lutris = {
    enable = lib.mkEnableOption "Enable lutris module";
  };

  config = lib.mkIf config.apps.launchers.games.lutris.enable {
    programs.lutris = {
      enable = true;
      protonPackages = [
        pkgs.proton-ge-bin
      ];
      winePackages = [
        pkgs.wineWow64Packages.full
      ];
    };
  };
}
