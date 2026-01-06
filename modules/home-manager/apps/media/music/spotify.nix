{config, pkgs, lib, ...}:

let
        cfg = config.apps.media.music.spotify;
in
{
	options.apps.media.music.spotify = {
		enable = lib.mkEnableOption "Enable spotify module";
	};

	config = lib.mkIf config.apps.media.music.spotify.enable {
		home.packages = with pkgs; [
			spotify
		];
	};
}
