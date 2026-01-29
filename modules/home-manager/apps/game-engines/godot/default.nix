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
    ./editors
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
      package = lib.mkIf cfg.mono pkgs.godot-mono;
      settings = cfg.settings;
    };
  };
}
