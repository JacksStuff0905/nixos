{
  config,
  lib,
  pkgs,
  util,
  inputs,
  ...
}:
let
  cfg = config.themes;

  file_to_not_import = [
    "default.nix"
  ];

  availableThemes = builtins.map (f: builtins.baseNameOf f) (util.get-import-dir ./. file_to_not_import);
in
{
  imports = lib.mkMerge [
    (inputs.stylix.homeModules.stylix)
  ];

  options.themes = {
    enable = lib.mkEnableOption "Enable theme module";

    stylix = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    theme = {
      name = lib.mkOption {
        type = lib.types.enum availableThemes;
        default = "godot";
      };

      style = lib.mkOption {
        type = lib.types.enum [
          "dark"
          "light"
        ];
        default = "dark";
      };
    };
  };


  config = lib.mkIf cfg.enable {
    programs.nvim-nix = lib.mkIf (config.programs.nvim != null) {
      themes.theme = {
        name = cfg.theme.name;
        style = cfg.theme.style;
      };
    };

    stylix = cfg.stylix {
      enable = true;
      base16Scheme = ./. + "/${cfg.theme.name}/base16.yaml";
    };
  };
}
