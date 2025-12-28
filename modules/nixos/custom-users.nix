{lib, config, pkgs, ...}:
{
	options = {
		custom-users.enable
			= lib.mkEnableOption "enable custom users module";

		custom-users.users.jacek = {
			enable = lib.mkEnableOption {
				default = true;
			};
			groups = lib.mkOption {
				type = lib.types.set;
				default = [ "wheel" ];
			};
			isNormalUser = lib.mkOption {
				type = lib.types.bool;
				default = true;
			};
			shell = lib.mkOption {
				default = pkgs.zsh;
			};
		};
	};

	config = lib.mkIf config.custom-users.enable {
		users.users = lib.mapAttrs
		(name: cfg:
			 lib.nameValuePair
			 "${name}"
			 {
				 isNormalUser = cfg.isNormalUser;
				 extraGroups = [];#cfg.groups;
				 shell = cfg.shell;
			 }
		)
		lib.filterAttrs (_: v: v.enable) config.custom-users.users;
	};
}
