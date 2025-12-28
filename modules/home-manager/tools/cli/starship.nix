{config, lib, pkgs, ...}:

{
	options.tools.cli.starship = {
		enable = lib.mkEnableOption "Enable starship module";
	};

	config = lib.mkIf config.tools.cli.starship.enable {
		programs.starship = {
			enable = true;
			enableZshIntegration = config.programs.zsh.enable;
			enableBashIntegration = config.programs.bash.enable;

			
			settings = {
				"$schema" = ''https://starship.rs/config-schema.json'';

				format = lib.concatStrings = [
					''[ ](fg:bg_color1)''
					''$os''
					''$username''
					''[](bg:bg_color2 fg:bg_color1)''
					''$directory''
					''[](fg:bg_color2 bg:bg_color3)''
					''$git_branch''
					''$git_status''
					''[](fg:bg_color3 bg:bg_color4)''
					''$c''
					''$cpp''
					''$rust''
					''$golang''
					''$nodejs''
					''$php''
					''$java''
					''$kotlin''
					''$haskell''
					''$python''
					''[](fg:bg_color4 bg:bg_color5)''
					''$docker_context''
					''$conda''
					''$pixi''
					''[](fg:bg_color5 bg:bg_color6)''
					''$time''
					''[ ](fg:bg_color6)''
					''$line_break $character ''
				];

				os = {
					disabled = false;
					style = "bg:bg_color1 fg:os_color";
				};

				os.symbols = {
					Windows = "󰍲";
					Ubuntu = "󰕈";
					SUSE = "";
					Raspbian = "󰐿";
					Mint = "󰣭";
					Macos = "󰀵";
					Manjaro = "";
					Linux = "󰌽";
					Gentoo = "󰣨";
					Fedora = "󰣛";
					Alpine = "";
					Amazon = "";
					Android = "";
					Arch = "󰣇";
					Artix = "󰣇";
					EndeavourOS = "";
					CentOS = "";
					Debian = "󰣚";
					Redhat = "󱄛";
					RedHatEnterprise = "󱄛";
					Pop = "";
				};

				username = {
					show_always = true;
					style_user = "bg:bg_color1 fg:text_color";
					style_root = "bg:bg_color1 fg:text_color";
					format = ''[ $user ]($style bold)'';
				};

				directory = {
					style = "fg:directory_color bg:bg_color2";
					format = ''[ 󰝰 $path ]($style bold)'';
					truncation_length = 3;
					truncation_symbol = "…/";
				};

				directory.substitutions = {
					"Documents" = "󰈙 ";
					"Downloads" = " ";
					"Music" = "󰝚 ";
					"Pictures" = " ";
					"Developer" = "󰲋 ";
				};

				git_branch = {
					symbol = "";
					style = "bg:bg_color3";
					format = ''[[ $symbol $branch ](fg:git_color bg:bg_color3)]($style)'';
				};

				git_status = {
					style = "bg:bg_color3";
					format = ''[[($all_status$ahead_behind )](fg:git_color bg:bg_color3)]($style)'';
				};

				nodejs = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:text_color bg:bg_color4)]($style)'';
				};

				c = {
					symbol = " ";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				cpp = {
					symbol = " ";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				rust = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				golang = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				php = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				java = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				kotlin = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				haskell = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				python = {
					symbol = "";
					style = "bg:bg_color4";
					format = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
				};

				docker_context = {
					symbol = "";
					style = "bg:bg_color5";
					format = ''[[ $symbol( $context) ](fg:docker_color bg:bg_color5)]($style)'';
				};

				conda = {
					style = "bg:bg_color5";
					format = ''[[ $symbol( $environment) ](fg:conda_color bg:bg_color5)]($style)'';
				};

				pixi = {
					style = "bg:bg_color5";
					format = ''[[ $symbol( $version)( $environment) ](fg:pixi_color bg:bg_color5)]($style)'';
				};

				time = {
					disabled = false;
					time_format = "%R";
					style = "bg:bg_color6";
					format = ''[[  $time ](fg:time_color bg:bg_color6)]($style)'';
				};

				line_break = {
					disabled = false;
				};

				character = {
					disabled = false;
					success_symbol = ''[](bold fg:success_color)'';
					error_symbol = "[](bold fg:error_color)";
					vimcmd_symbol = "[](bold fg:success_color)";
					vimcmd_replace_one_symbol = "[](bold fg:replace_color)";
					vimcmd_replace_symbol = "[](bold fg:replace_color)";
					vimcmd_visual_symbol = "[](bold fg:bg_color2)";
				};
			};
		};
	};
}
