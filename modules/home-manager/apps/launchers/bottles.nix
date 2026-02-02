{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.launchers.bottles;
in
{
  options.apps.launchers.bottles = {
    enable = lib.mkEnableOption "Enable kitty module";
  };

  config = lib.mkIf config.apps.launchers.bottles.enable {
    home.packages = with pkgs; [
      bottles
    ];
  };
}
