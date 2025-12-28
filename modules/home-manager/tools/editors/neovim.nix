{config, lib, pkgs, ...}:

{
	options.tools.editors.neovim = {
		enable = lib.mkEnableOption "Enable neovim module";
	};

	config = lib.mkIf config.tools.editors.neovim.enable {
		programs.neovim = {
			enable = true;
		};
	};
}
