{config, lib, pkgs, ...}:

let
	cfg = config.bootloader.systemd-boot;
in
{
	options.bootloader.systemd-boot = {
		enable = lib.mkEnableOption {
			description = "Enable systemd-boot module";
			default = false;
		};
	};

	config = lib.mkIf cfg.enable {
		boot.loader.systemd-boot.enable = true;
	};
}
