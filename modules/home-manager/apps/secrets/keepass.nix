{config, lib, pkgs, ...}:

{
	options.apps.secrets.keepass = {
		enable = lib.mkEnableOption "Enable keepass module";
	};

	config = lib.mkIf config.apps.secrets.keepass.enable {
		programs.keepassxc.enable = true;
	};
}
