{ lib }:

with lib;

types.submodule (
  { name, ... }:
  {
    options = {
      enable = mkEnableOption "this blueprint" // {
        default = true;
      };

      name = mkOption {
        type = types.str;
        default = name;
        description = "Blueprint name";
      };

      metadata = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Blueprint metadata";
      };

      context = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Blueprint context variables";
      };

      entries = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = "Blueprint entries";
      };

      content = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Raw YAML content (overrides entries)";
      };

      file = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to YAML file (overrides all)";
      };
    };
  }
)
