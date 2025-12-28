{pkgs, config, lib, ...}:

{
	options.apps.godot = {
		enable = lib.mkEnableOption "Enable godot module";
	};

	config = lib.mkIf config.apps.godot.enable {
		home.packages = [
			pkgs.godot
		];
	};
}
