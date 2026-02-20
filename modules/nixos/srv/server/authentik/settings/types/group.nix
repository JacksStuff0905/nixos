{ lib }:

with lib;

types.submodule (
  { name, ... }:
  {
    options = {
      enable = mkEnableOption "this group" // {
        default = true;
      };

      name = mkOption {
        type = types.str;
        default = name;
        description = "Group name";
      };

      isSuperuserGroup = mkOption {
        type = types.bool;
        default = false;
        description = "Whether members are superusers";
      };

      parent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Parent group naat /nix/store/16hs2k6w5qfdk0dg12i53hxy7v6lbnsl-source/modules/nixos/srv/server/authentik/settings/blueprints/users.nix:80:27:me";
      };

      attributes = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Custom group attributes";
      };

      roles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Roles assigned to this group";
      };
    };
  }
)
