
{config, pkgs, lib, ...}:
let
  cfg = config.de.hyprland;
in
{
  imports = [
    ./keybinds.nix
    ./windows.nix
  ];

	options.de.hyprland = {
		enable = lib.mkEnableOption "Enable hyprland module";
    theme = lib.mkOption {
      type = lib.types.str;
      default = config.themes.theme;
    };
	};

	config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor=",highrr,auto,auto";


        "$terminal" = "kitty";
        "$fileManager" = "nautilus";
        "$menu" = ''rofi -show drun --allow-images --insensitive --prompt "..."'';
        "$browser" = "firefox";

        exec-once = [ "waybar & swaync & hypridle"
          "hyprpaper"
          "systemctl --user start hyprpolkitagent"
        ];


        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
        ];


        input = {
          kb_layout = "pl";
          follow_mouse = 1;

          sensitivity = 0.05; # -1.0 - 1.0, 0 means no modification.
          accel_profile = "flat";

          touchpad = {
            natural_scroll = false;
          };
        };

        "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier
      };
    };
  };
}
