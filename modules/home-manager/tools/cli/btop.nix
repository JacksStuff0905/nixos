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
    enableRocm = lib.mkEnableOption "rocm";
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
      package = lib.mkIf cfg.enableRocm pkgs.btop-rocm;
    };
  };
}
