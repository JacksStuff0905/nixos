{config, pkgs, lib, ...}:
let
  cfg = config.dm.gdm;
in
{
	options.dm.gdm = {
		enable = lib.mkEnableOption "Enable gdm module";
	};

	config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.displayManager.gdm.enable = true;
	};
}
