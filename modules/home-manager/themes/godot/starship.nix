{pkgs, config, lib, ...}:

{

	config = lib.mkIf config.programs.starship.enable {
		programs.starship = {
			settings = {
				palette = "godot-theme";

				palettes = {
					godot-theme = {
						text_color = "#13354A";
						os_color = "#13354A";
						bg_color1 = "#57B3FF";
						directory_color = "#403D3D";
						bg_color2 = "#A6E22E";
						git_color = "#333333";
						bg_color3 = "#EF5939";
						lang_color = "#4C4745";
						bg_color4 = "#FF7085";
						docker_color = "#66D9EF";
						conda_color = "#66D9EF";
						pixi_color = "#66D9EF";
						bg_color5 = "#1B1D1E";
						time_color = "#FFEDA1";
						bg_color6 = "#2D3138";
						success_color = "#FFB373";
						error_color = "#F92672";
						replace_color = "#E6DB74";
					};
				};
			};
		};
	};
}
