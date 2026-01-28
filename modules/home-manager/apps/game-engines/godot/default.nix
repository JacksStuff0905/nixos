{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.apps.game-engines.godot;
in
{
  imports = [
    inputs.godot-nix.homeManagerModules.default
  ];

  options.apps.game-engines.godot = {
    enable = lib.mkEnableOption "Enable godot module";
    mono = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable mono / C# support";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.godot-nix = {
      enable = true;
      mono = cfg.mono;
      settings = cfg.settings;
        text_editor.external.exec_path = (lib.getExe);
        text_editor.external.use_external_editor = true;
    };
  };
}
