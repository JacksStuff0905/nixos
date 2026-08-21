{config, pkgs, lib, ...}:
let
  cfg = config.dm.sddm;
in
{
	options.dm.sddm = {
		enable = lib.mkEnableOption "Enable sddm module";
	};

	config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.displayManager.sddm.enable = true;
	};
}
