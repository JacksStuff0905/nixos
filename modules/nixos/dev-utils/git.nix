{config, pkgs, lib, ...}:

{
	options.dev-utils.git = {
		enable = lib.mkEnableOption "Enable git module";
	};

	config = lib.mkIf config.dev-utils.git.enable {
		  environment.systemPackages = with pkgs; [
			git
		  ];
	};
}
