{config, pkgs, lib, ...}:

{
	options.dev-utils.neovim = {
		enable = lib.mkEnableOption "Enable neovim module";
	};

	config = lib.mkIf config.dev-utils.neovim.enable {
		  environment.systemPackages = with pkgs; [
			neovim
		  ];
	};
}
