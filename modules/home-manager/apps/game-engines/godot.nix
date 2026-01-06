{pkgs, config, lib, ...}:

let
        cfg = config.apps.game-engines.godot;
in
{
	options.apps.game-engines.godot = {
		enable = lib.mkEnableOption "Enable godot module";
                mono-support = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Enable mono / C# support";
                };
	};

	config = lib.mkIf config.apps.game-engines.godot.enable {
		home.packages = with pkgs; [
			if (cfg.mono-support) then godot-mono else godot
		];
	};
}
