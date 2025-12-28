{pkgs, config, lib, ...}:

{
	options.apps.kitty = {
		enable = lib.mkEnableOption "Enable kitty module";
	};

	config = lib.mkIf config.apps.kitty.enable {
		programs.kitty = {
			enable = true;
			settings = {
				scrollback_lines = 2000;

				font_size = 14;

				background_opacity = 0.9;

				confirm_os_window_close = 0;

				# Hide mouse when typing
				mouse_hide_wait	= -3.0;


				# Tab bar config
				tab_bar_edge = "bottom";

				font_family = "Caskaydia Cove Nerd Font";
				bold_font = "auto";
				italic_font = "auto";
				bold_italic_font = "auto";
			};

			keybindings = {
				"ctrl+shift+l" = "next_tab";
				"ctrl+shift+h" = "previous_tab";
				"ctrl+shift+n" = "new_tab";
				"ctrl+shift+k" = "move_tab_forward";
				"ctrl+shift+j" = "move_tab_backward";
			};
		};
	};
}
