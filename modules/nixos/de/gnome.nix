{config, pkgs, lib, ...}:
let
  cfg = config.de.gnome;
in
{
	options.de.gnome = {
		enable = lib.mkEnableOption "Enable gnome module";
	};

	config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.gnome.enable = true;
	};
}
