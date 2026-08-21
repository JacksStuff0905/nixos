{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tools.cli.btop;
in
{
  options.tools.cli.btop = {
    enable = lib.mkEnableOption "btop";
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
    };
  };
}
