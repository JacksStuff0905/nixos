
{config, pkgs, lib, ...}:
let
  cfg = config.de.hyprland;
in
{
	options.de.hyprland = {
		enable = lib.mkEnableOption "Enable hyprland module";
	};

	config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
	};
}
