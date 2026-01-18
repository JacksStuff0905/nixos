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

  cfg = config.virtualization.docker;
in
{
  imports = util.get-import-dir ./. file_to_not_import;

  options.virtualization.docker = {
    enable = lib.mkEnableOption "Enable docker module";
    rootless = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    use-for-oci = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;

      rootless = lib.mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
      };

      enableOnBoot = true;
    };

    users.groups.docker.members = cfg.users;

    virtualisation.oci-containers.backend = lib.mkIf cfg.use-for-oci "docker";
  };
}
