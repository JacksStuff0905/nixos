{config, pkgs, lib, ...}:

{
	options.apps.spotify = {
		enable = lib.mkEnableOption "Enable spotify module";
	};

	config = lib.mkIf config.apps.spotify.enable {
		home.packages = [
			pkgs.spotify
		];
	};
}
