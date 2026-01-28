{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  available-themes =
    if (builtins.pathExists ./themes) then builtins.attrNames (builtins.readDir ./themes) else [ ];

  cfg = config.tools.editors.neovim;
in
{
  imports = [
    inputs.nvim-nix.homeManagerModules.default
  ];

  options.tools.editors.neovim = {
    enable = lib.mkEnableOption "Enable the nvim-nix managment module";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "full";
    };

    theme = {
      name = lib.mkOption {
        type = lib.types.str;
        default = config.themes.theme.name;
      };

      style = lib.mkOption {
        type = lib.types.enum [
          "dark"
          "light"
        ];
        default = config.themes.theme.style;
      };
    };
  };

  config.programs.nvim-nix = lib.mkIf cfg.enable {
    enable = true;

    profile = cfg.profile;

    themes = {
      enable = true;

      theme = {
        name = cfg.theme.name;
        style = cfg.theme.style;

        path = (
          if (builtins.elem cfg.theme.name available-themes) then ./themes + ("/" + cfg.theme.name) else null
        );
      };
    };
  };
}
