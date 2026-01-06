{config, lib, pkgs, ...}:
let
        cfg = config.tools.cli.git;
in
{
	options.tools.cli.git = {
		enable = lib.mkEnableOption "Enable zoxide module";
                user = {
                        name = lib.mkOption {
                                type = lib.types.str;
                                default = "Jacek Sawiński";
                        };
                        email = lib.mkOption {
                                type = lib.types.str;
                                default = "jacek.sawinski.0905@gmail.com";
                        };
                };
	};

	config = lib.mkIf config.tools.cli.git.enable {
                programs.git = {
                        enable = true;
                        settings = {
                                user = cfg.user;
                        };
                };
	};
}
