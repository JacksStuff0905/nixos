{lib, config, pkgs, ...}:

{
	options.sh.zsh = {
		enable = lib.mkEnableOption "Enable zsh module";

	};

	config = lib.mkIf config.sh.zsh.enable {
		programs.zsh = {
			enable = true;

			autosuggestions.enable = true;
			syntaxHighlighting = {
				enable = true;
			};
		};
	};
}
