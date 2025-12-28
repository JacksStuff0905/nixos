{lib, config, pkgs, ...}:
let
	cfg = config.main-user;
in
{
	options = {
		main-user.enable
			= lib.mkEnableOption "enable user module";

		main-user.userName = lib.mkOption {
			default = "jacek";
			description = ''
				username
			'';
		};
		main-user.extraGroups = lib.mkOption {
			description = ''
				Additional user groups
			'';
		};
	};

	config = lib.mkIf cfg.enable {
		users.users.${cfg.userName} = {
			isNormalUser = true;
			description = "jacek";
			shell = pkgs.zsh;
		};
	};
}
