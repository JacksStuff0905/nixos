{
  config,
  lib,
  pkgs,
  util,
  ...
}:

let
  file_to_not_import = [
    "default.nix"
  ];

  cfg = config.tools.virtualization.docker;
in
{
  imports = util.get-import-dir ./. file_to_not_import;

  options.tools.virtualization.docker = {
    enable = lib.mkEnableOption "Enable docker module";

    compose = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; lib.mkIf cfg.compose [
      docker-compose
    ];
  };
}
