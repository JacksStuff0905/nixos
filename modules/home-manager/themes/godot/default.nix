{config, lib, pkgs, util, ...}:

let
  file_to_not_import = [
    "default.nix"
  ];
in
{
	imports = util.get-import-dir ./. file_to_not_import;

	options.themes.godot = {
		enable = lib.mkEnableOption "Enable godot theme module";
	};

	config = lib.mkIf config.themes.godot.enable {};
}
