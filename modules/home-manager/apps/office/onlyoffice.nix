{config, lib, pkgs, ...}:

{
	options.apps.office.onlyoffice = {
		enable = lib.mkEnableOption "Enable onlyoffice module";
	};

	config = lib.mkIf config.apps.office.onlyoffice.enable {
    home.packages = with pkgs; [
      onlyoffice-desktopeditors
    ];
	};
}
