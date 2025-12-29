{config, lib, pkgs, ...}:

{
	options.apps.keepass = {
		enable = lib.mkEnableOption "Enable keepass module";
	};

	config = lib.mkIf config.apps.keepass.enable {
		programs.keepassxc.enable = true;
	};
}
