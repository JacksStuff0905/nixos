{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.game-engines.godot;
in
{
  options.apps.game-engines.godot = {
    editors = {
      neovim = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
  };

  config.apps.game-engines.godot.editors = lib.mkIf cfg.enable {
    settings = lib.mkMerge [
      (lib.mkIf cfg.editors.neovim.enable {
        text_editor.external.exec_path = (lib.getExe config.programs.nvf.finalPackage);
        text_editor.external.use_external_editor = true;
      })
    ];
  };
}
