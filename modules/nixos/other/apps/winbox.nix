{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.other.apps.winbox;
in
{
  options.other.apps.winbox = {
    enable = lib.mkEnableOption "winbox";
  };

  config = lib.mkIf cfg.enable {
    programs.winbox = {
      enable = true;
      openFirewall = true;
    };
  };
}
