{config, lib, pkgs, ...}:

{
	options.apps.office.libreoffice = {
		enable = lib.mkEnableOption "Enable libreoffice module";
	};

	config = lib.mkIf config.apps.office.libreoffice.enable {
    home.packages = with pkgs; [
      libreoffice
    ];
	};
}
