{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.games.minecraft;
in
{
  options.apps.games.minecraft = {
    enable = lib.mkEnableOption "minecraft";
    launchers = {
      prism = {
        enable = lib.mkEnableOption "prism launcher";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.mkMerge [
        (lib.mkIf cfg.launchers.prism.enable [ prismlauncher ])
      ];
  };
}
