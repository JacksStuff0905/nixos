{config, lib, pkgs, util, ...}:

let
  file_to_not_import = [
    "default.nix"
  ];
in
{
  imports = util.get_import_dir ./. file_to_not_import;
}
