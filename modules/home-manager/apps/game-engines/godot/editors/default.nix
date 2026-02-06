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

  config.programs.godot-nix = lib.mkIf cfg.enable {
    settings = lib.mkMerge [
      (lib.mkIf cfg.editors.neovim.enable {
        text_editor.external.exec_path = (lib.getExe config.programs.nvf.finalPackage);
        text_editor.external.exec_flags = ''--server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line},{col})<CR>"'';
        text_editor.external.use_external_editor = true;
      })
    ];
  };
}
