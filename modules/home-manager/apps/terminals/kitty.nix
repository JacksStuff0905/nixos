{pkgs, config, lib, ...}:

let
        cfg = config.apps.terminals.kitty;
        font =
                if (cfg.font-override.enable) then
                        cfg.font-override.font
                else
                        "monospace";
in
{
	options.apps.terminals.kitty = {
		enable = lib.mkEnableOption "Enable kitty module";
                font-override = {
                        enable = lib.mkEnableOption "Enable font override";
                        font = lib.mkOption {
                                type = lib.types.str;
                                default = "Caskaydia Cove Nerd Font";
                        };
                };

                font-size = lib.mkOption {
                        type = lib.types.int;
                        default = 14;
                };

                settings = lib.mkOption {
                        type = lib.types.attrs;
                        default = {
				scrollback_lines = 2000;

				background_opacity = 0.9;

				confirm_os_window_close = 0;

				# Hide mouse when typing
				mouse_hide_wait	= -3.0;


				# Tab bar config
				tab_bar_edge = "bottom";

			};
                };

                keymaps = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = {
                                "ctrl+shift+l" = "next_tab";
                                "ctrl+shift+h" = "previous_tab";
                                "ctrl+shift+n" = "new_tab";
                                "ctrl+shift+k" = "move_tab_forward";
                                "ctrl+shift+j" = "move_tab_backward";
                        };
                };
	};

	config = lib.mkIf config.apps.terminals.kitty.enable {
		programs.kitty = {
			enable = true;
			settings = lib.mkMerge [
                                cfg.settings
                        ];

                        font = {
                                name = font;
				size = cfg.font-size;
                        };

			keybindings = cfg.keymaps;
		};
	};
}
