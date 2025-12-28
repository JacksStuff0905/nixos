{config, pkgs, lib, ...}:

{
	options.dev-utils.gnumake = {
		enable = lib.mkEnableOption "Enable GNU make module";
	};

	config = lib.mkIf config.dev-utils.gnumake.enable {
		  environment.systemPackages = with pkgs; [
			gnumake
		  ];
	};
}
