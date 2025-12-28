{config, lib, ...}:

{
	options.sh.aliases = {
		enable = lib.mkEnableOption "Enable shell aliases module";
	};

	config = lib.mkIf config.sh.aliases.enable {
		environment.shellAliases = {
			".." = "cd ..";
		};
	};
}
