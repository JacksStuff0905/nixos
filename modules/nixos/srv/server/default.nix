{config, lib, pkgs, util, ...}:

let
  file_to_not_import = [
    "default.nix"
  ];
in
{
  imports = util.get-import-dir ./. file_to_not_import;
}
