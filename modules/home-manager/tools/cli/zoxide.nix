{config, lib, pkgs, ...}:

{
	options.tools.cli.zoxide = {
		enable = lib.mkEnableOption "Enable zoxide module";
	};

	config = lib.mkIf config.tools.cli.zoxide.enable {
		programs.zoxide = {
			enable = true;
		};
	};
}
