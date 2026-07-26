{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.de.xfce;
in
{
  options.de.xfce = {
    enable = lib.mkEnableOption "Enable xfce module";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
    };
  };
}
