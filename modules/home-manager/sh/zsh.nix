{config, lib, pkgs, ...}:

{
	options.sh.zsh = {
		enable = lib.mkEnableOption "Enable zsh module";
	};

	config = lib.mkIf config.sh.zsh.enable {
		home.sessionVariables = {
			  # 1. Enable mode-dependent cursor shapes
			  ZVM_CURSOR_STYLE_ENABLED="true";
			  ZVM_VIINS_CURSOR_STYLE="beam";
			  ZVM_VICMD_CURSOR_STYLE="block";
			  ZVM_VISUAL_CURSOR_STYLE="block";

			  ZVM_SYSTEM_CLIPBOARD_ENABLED="true";

			  ZVM_LINE_INIT_MODE="$ZVM_MODE_INSERT";

			  # 2. Optional: enable indicator in the right prompt
			  ZVM_MODE_CURSOR="true";
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
			
			initContent = lib.mkIf config.programs.fastfetch.enable ''
				if [[ -o interactive ]] && [[ -z "$VSCODE_SHELL_INTEGRATION" ]]; then
					fastfetch
				fi	
			'';
		};
	};
}
