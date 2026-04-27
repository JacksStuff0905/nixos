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

  cfg = config.virtualization.virt-manager;
in
{
  imports = util.get-import-dir ./. file_to_not_import;

  options.virtualization.virt-manager = {
    enable = lib.mkEnableOption "Enable virt-manager module";
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    programs.virt-manager = {
      enable = true;
    };

    users.groups.libvirtd.members = cfg.users;

    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };
  };
}
