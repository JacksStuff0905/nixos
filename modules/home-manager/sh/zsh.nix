{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sh.zsh;
in
{
  options.sh.zsh = {
    enable = lib.mkEnableOption "Enable zsh module";
    fetch = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.sh.zsh.enable {
    home.sessionVariables = {
      ZVM_CURSOR_STYLE_ENABLED = "true";
      ZVM_VIINS_CURSOR_STYLE = "beam";
      ZVM_VICMD_CURSOR_STYLE = "block";
      ZVM_VISUAL_CURSOR_STYLE = "block";

      ZVM_SYSTEM_CLIPBOARD_ENABLED = "true";

      ZVM_LINE_INIT_MODE = "$ZVM_MODE_INSERT";

      ZVM_MODE_CURSOR = "true";
    };

    programs.zsh = {
      enable = true;

      plugins = [
        {
          name = "zsh-vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.zsh";
        }
      ];

      enableCompletion = true;
      initContent = lib.mkMerge [
        (lib.mkIf (config.programs.fastfetch.enable && cfg.fetch) ''
          if [[ -o interactive ]] && [[ -z "$VSCODE_SHELL_INTEGRATION" ]]; then
            fastfetch
          fi	
        '')

        (''
          # Case insensitive completions
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
          zstyle ':completion:*' menu select
        '')
      ];
    };
  };
}
