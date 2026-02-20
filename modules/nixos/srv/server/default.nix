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

  types = {
    host = types.submodule {
      options = with lib.types; {
        name = lib.mkOption { type = str; };
      };
    };
  };
in
{
  imports = util.get-import-dir ./. file_to_not_import;

  options.srv.server = {
    domain = lib.mkOption {
      type = lib.types.str;
    };

    hosts = {
      required = {
        proxy = lib.mkOption {
          type = types.host;
        };

        auth = lib.mkOption {
          type = types.host;
        };

        nas = lib.mkOption {
          type = types.host;
        };
      };

      other = lib.mkOption {
        type = lib.types.attrsOf types.host;
        default = { };
      };
    };
  };
}
