{ lib }:

with lib;

types.submodule (
  { name, ... }:
  {
    options = {
      enable = mkEnableOption "this user" // {
        default = true;
      };

      username = mkOption {
        type = types.str;
        default = name;
        description = "Username";
      };

      name = mkOption {
        type = types.str;
        default = name;
        description = "Display name";
      };

      email = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Email address";
      };

      isActive = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the user is active";
      };

      isSuperuser = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the user is a superuser";
      };

      groups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Groups the user belongs to";
      };

      attributes = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Custom user attributes";
      };

      type = mkOption {
        type = types.enum [
          "internal"
          "external"
          "service_account"
          "internal_service_account"
        ];
        default = "internal";
        description = "User type";
      };

      path = mkOption {
        type = types.str;
        default = "users";
        description = "User path";
      };

      state = mkOption {
        type = types.enum [
          "present"
          "created"
          "absent"
        ];
        default = "present";
        description = ''
          - "created": Create once, never update (password safe)
          - "present": Update on every apply
          - "absent": Delete user
        '';
      };
    };
  }
)
