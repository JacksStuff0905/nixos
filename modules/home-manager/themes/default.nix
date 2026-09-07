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

  availableThemes = builtins.map (f: (lib.removeSuffix ".nix" (builtins.baseNameOf f))) (
    util.get-import-dir ./. file_to_not_import
  );
in
{
  imports = [
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
    stylix =
      let
        theme = import (./. + "/${cfg.theme.name}.nix") { inherit pkgs lib; };
      in
      lib.mkIf cfg.stylix (
        theme
        // {
          enable = true;
        }
      );
  };
}
