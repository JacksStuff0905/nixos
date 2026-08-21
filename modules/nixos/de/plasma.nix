{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.de.plasma;
in
{
  options.de.plasma = {
    enable = lib.mkEnableOption "Enable plasma module";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.plasma6.enable = true;
  };
}
