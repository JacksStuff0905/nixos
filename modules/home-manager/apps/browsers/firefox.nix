{pkgs, config, lib, inputs, ...}:
let
  cfg = config.apps.browsers.firefox;
in
{
  options.apps.browsers.firefox = {
    enable = lib.mkEnableOption "Enable firefox module";
  };

  config.programs.firefox = lib.mkIf cfg.enable {
		enable = true;
	};
}
