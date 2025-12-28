{config, lib, pkgs, ...}:

let
	cfg = config.bootloader.grub;
in
{
	options.bootloader.grub = {
		enable = lib.mkEnableOption {
			description = "Enable grub module";
			default = true;
		};

		useOSProber = lib.mkOption {
			type = lib.types.bool;
			default = true;
		};
	};

	config = lib.mkIf cfg.enable {
		boot.loader.efi.canTouchEfiVariables = true;
		boot.loader.grub.enable = true;
		boot.loader.grub.devices = [ "nodev" ];
		boot.loader.grub.useOSProber = cfg.useOSProber;
		boot.loader.grub.efiSupport = true;

		boot.loader.systemd-boot.enable = false;
	};
}
