{config, lib, pkgs, ...}:

{
	options.sh.env-vars = {
		enable = lib.mkEnableOption "Enable environment variable module";
	};

	config = lib.mkIf config.sh.env-vars.enable {
		home.sessionVariables = lib.mkMerge [
			# Neovim
			(lib.optionalAttrs config.programs.neovim.enable {
				MANPAGER = "nvim +Man!";
				EDITOR = "$(which nvim)";
			})
		];
	};
}
