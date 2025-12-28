{pkgs, config, lib, ...}:

{
	options.fonts.nerd-fonts-caskaydia-cove = {
		enable = lib.mkEnableOption "Enable godot module";
	};

	config = lib.mkIf config.fonts.nerd-fonts-caskaydia-cove.enable {
		home.packages = [
			pkgs.nerd-fonts.caskaydia-cove
		];

		fonts.fontconfig.enable = true;
	};
}

