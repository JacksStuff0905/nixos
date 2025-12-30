{config, lib, pkgs, util, ...}:

let
  file_to_not_import = [
    "default.nix"
    "current-theme"
  ];
in
{
	imports = util.get-import-dir ./. file_to_not_import;

	config = lib.mkIf config.programs.neovim.enable {
		xdg.configFile."nvim/current-theme" = {
			recursive = true;
			source = ./current-theme;
		};
	};
}
