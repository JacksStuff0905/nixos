{config, lib, pkgs, ...}:

{
	options.sh.aliases = {
		enable = lib.mkEnableOption "Enable shell alias module";
	};

	config = lib.mkIf config.sh.aliases.enable {
		home.shellAliases = lib.mkMerge [
			# Kitty
			(lib.optionalAttrs config.programs.kitty.enable {
				icat = "kitten icat";
				ssh = "kitten ssh";
			})

			# Zoxide
			(lib.optionalAttrs config.programs.zoxide.enable {
				cd = "z";
			})
		];
	};
}
