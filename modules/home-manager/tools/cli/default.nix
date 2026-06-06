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

  defaultEnable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  cfg = config.tools.cli;
in
{
  imports = util.get-import-dir ./. file_to_not_import;

  options.tools.cli = {
    tree.enable = defaultEnable;
    samba.enable = defaultEnable;
    zip.enable = defaultEnable;
  };

  config = {
    home.packages = lib.mkMerge [
      (lib.mkIf cfg.tree.enable [ pkgs.tree ])
      (lib.mkIf cfg.samba.enable [ pkgs.samba ])
      (lib.mkIf cfg.zip.enable [
        pkgs.zip
        pkgs.unzip
      ])
    ];
  };
}
