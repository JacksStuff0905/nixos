{ lib }:

with lib;

types.submodule {
  options = {
    createGroup = mkOption {
      type = types.bool;
      default = false;
      description = "Create a dedicated access group";
    };

    groupName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Access group name (defaults to '<app slug>')";
    };

    allowedGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Existing groups allowed access";
    };

    policyEngineMode = mkOption {
      type = types.enum [
        "any"
        "all"
      ];
      default = "any";
      description = "Policy engine mode";
    };

    customPolicy = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Custom Python policy expression";
    };
  };
}
