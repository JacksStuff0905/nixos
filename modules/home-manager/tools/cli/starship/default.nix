{config, lib, pkgs, ...}:

let
        cfg = config.tools.cli.starship;

        available-themes = lib.mapAttrsToList (name: type: lib.removeSuffix ".nix" name) (builtins.readDir ./themes);

        current-theme = (import (./themes + ("/" + cfg.theme.name + ".nix")))."${cfg.theme.style}";

        mkLang = symbol: lib.mkOption { type = lib.types.str; default = symbol; };
        mkEnv = format: lib.mkOption { type = lib.types.str; default = format; };
in
{
	options.tools.cli.starship = {
		enable = lib.mkEnableOption "Enable starship module";

                theme = {
                        name = lib.mkOption {
                                type = lib.types.enum available-themes;
                                default = config.themes.theme.name;
                        };
                        style = lib.mkOption {
                                type = lib.types.enum ["light" "dark"];
                                default = config.themes.theme.style;
                        };
                };

                format = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = lib.flatten [
                                ''[ ](fg:bg_color1)''
                                ''$os''
                                ''$username''
                                ''[](bg:bg_color2 fg:bg_color1)''
                                ''$directory''
                                ''[](fg:bg_color2 bg:bg_color3)''
                                cfg.format-elements.git
                                ''[](fg:bg_color3 bg:bg_color4)''
                                cfg.format-elements.languages
                                ''[](fg:bg_color4 bg:bg_color5)''
                                cfg.format-elements.environments
                                ''[](fg:bg_color5 bg:bg_color6)''
                                ''$time''
                                ''[ ](fg:bg_color6)''
                                ''$line_break $character ''
                        ];
                };

                format-elements = lib.mkOption {
                        readOnly = true;
                        visible = false;
                        internal = true;
                        default = {
                                git = [''$git_branch'' ''$git_status''];

                                languages = (builtins.map (lang: "$" + lang) (builtins.attrNames cfg.elements.languages.symbols));

                                environments = (builtins.map (lang: "$" + lang) (builtins.attrNames cfg.elements.languages.symbols));
                        };
                };

                elements = {
                        os = {
                                enable = lib.mkOption {
                                        type = lib.types.bool;
                                        default = true;
                                };
                                style = lib.mkOption {
                                        type = lib.types.str;
                                        default = "bg:bg_color1 fg:os_color";
                                };
                        };

                        username = {
                                enable = lib.mkOption {
                                        type = lib.types.bool;
                                        default = true;
                                };
                                style = {
                                        user = lib.mkOption {
                                                type = lib.types.str;
                                                default = "bg:bg_color1 fg:text_color";
                                        };
                                        root = lib.mkOption {
                                                type = lib.types.str;
                                                default = "bg:bg_color1 fg:text_color";
                                        };
                                };
                                format = lib.mkOption {
                                        type = lib.types.str;
                                        default = ''[ $user ]($style bold)'';
                                };
                        };

                        directory = {
                                style = lib.mkOption {
                                        type = lib.types.str;
                                        default = "fg:directory_color bg:bg_color2";
                                };
                                format = lib.mkOption {
                                        type = lib.types.str;
                                        default = ''[ 󰝰 $path ]($style bold)'';
                                };
                                truncation = {
                                        length = lib.mkOption {
                                                type = lib.types.int;
                                                default = 3;
                                        };
                                        symbol = lib.mkOption {
                                                type = lib.types.str;
                                                default = "…/";
                                        };
                                };
                                substitutions = lib.mkOption {
                                        type = lib.types.attrsOf lib.types.str;
                                        default = {
                                                "Documents" = "󰈙 ";
                                                "Downloads" = " ";
                                                "Music" = "󰝚 ";
                                                "Pictures" = " ";
                                                "Developer" = "󰲋 ";
                                        };
                                };
                        };

                        git = {
                                branch = {
                                        symbol = lib.mkOption {
                                                type = lib.types.str;
                                                default = "";
                                        };
                                        style = lib.mkOption {
                                                type = lib.types.str;
                                                default = "bg:bg_color3";
                                        };
                                        format = lib.mkOption {
                                                type = lib.types.str;
                                                default = ''[[ $symbol $branch ](fg:git_color bg:bg_color3)]($style)'';
                                        };
                                };

                                status = {
                                        style = lib.mkOption {
                                                type = lib.types.str;
                                                default = "bg:bg_color3";
                                        };
                                        format = lib.mkOption {
                                                type = lib.types.str;
                                                default = ''[[($all_status$ahead_behind )](fg:git_color bg:bg_color3)]($style)'';
                                        };
                                };
                        };

                        languages = {
                                format = lib.mkOption {
                                        type = lib.types.str;
                                        default = ''[[ $symbol( $version) ](fg:lang_color bg:bg_color4)]($style)'';
                                };
                                style = lib.mkOption {
                                        type = lib.types.str;
                                        default = "bg:bg_color4";
                                };
                                
                                symbols = {
                                        nodejs = mkLang "";
                                        c = mkLang "";
                                        cpp = mkLang "";
                                        rust = mkLang "";
                                        golang = mkLang "";
                                        php = mkLang "";
                                        java = mkLang "";
                                        kotlin = mkLang "";
                                        haskell = mkLang "";
                                        python = mkLang "";
                                };
                        };

                        environments = {
                                style = lib.mkOption {
                                        type = lib.types.str;
                                        default = "bg:bg_color4";
                                };

                                formats = {
                                        docker_context = mkEnv ''[[ $symbol( $context) ](fg:docker_color bg:bg_color5)]($style)'';
                                        conda = mkEnv ''[[ $symbol( $environment) ](fg:conda_color bg:bg_color5)]($style)'';

                                        pixi = mkEnv ''[[ $symbol( $version)( $environment) ](fg:pixi_color bg:bg_color5)]($style)'';
                                };
                        };

                        time = {
                                enable = lib.mkOption {
                                        type = lib.types.bool;
                                        default = true;
                                };

                                time-format = lib.mkOption {
                                        type = lib.types.str;
                                        default = "%R";
                                };

                                style = lib.mkOption {
                                        type = lib.types.str;
                                        default = "bg:bg_color6";
                                };

                                format = lib.mkOption {
                                        type = lib.types.str;
                                        default = ''[[  $time ](fg:time_color bg:bg_color6)]($style)'';
                                };
                        };

                        line-break = {
                                enable = lib.mkOption {
                                        type = lib.types.bool;
                                        default = true;
                                };
                        };

                        character = {
                                enable = lib.mkOption {
                                        type = lib.types.bool;
                                        default = true;
                                };
                                success = lib.mkOption { type = lib.types.str; default = ''[](bold fg:success_color)''; };
                                error = lib.mkOption { type = lib.types.str; default = "[](bold fg:error_color)"; };
                                vimcmd = {
                                        symbol = lib.mkOption { type = lib.types.str; default = "[](bold fg:success_color)"; };
                                        replace-one = lib.mkOption { type = lib.types.str; default = "[R](bold fg:replace_color)"; };
                                        replace = lib.mkOption { type = lib.types.str; default = "[C](bold fg:replace_color)"; };
                                        visual = lib.mkOption { type = lib.types.str; default = "[V](bold fg:bg_color2)"; };
                                };
                        };
                };
	};

	config = lib.mkIf config.tools.cli.starship.enable {
		programs.starship = {
			enable = true;
			enableZshIntegration = config.programs.zsh.enable;
			enableBashIntegration = config.programs.bash.enable;
			enableFishIntegration = config.programs.fish.enable;

			
			settings = lib.mkMerge [
                                {
                                        "$schema" = ''https://starship.rs/config-schema.json'';
                                        
                                        palette = "${cfg.theme.name}";

                                        palettes."${cfg.theme.name}" = current-theme;

                                        format = lib.concatStrings cfg.format;

                                        os = {
                                                disabled = !cfg.elements.os.enable;
                                                style = cfg.elements.os.style;
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
                                                show_always = cfg.elements.username.enable;
                                                style_user = cfg.elements.username.style.user;
                                                style_root = cfg.elements.username.style.root;
                                                format = cfg.elements.username.format;
                                        };

                                        directory = {
                                                style = cfg.elements.directory.style;
                                                format = cfg.elements.directory.format;
                                                truncation_length = cfg.elements.directory.truncation.length;
                                                truncation_symbol = cfg.elements.directory.truncation.symbol;
                                        };

                                        directory.substitutions = cfg.elements.directory.substitutions;

                                        git_branch = cfg.elements.git.branch;

                                        git_status = cfg.elements.git.status;


                                        time = {
                                                disabled = !cfg.elements.time.enable;
                                                time_format = cfg.elements.time.time-format;
                                                style = cfg.elements.time.style;
                                                format = cfg.elements.time.format;
                                        };

                                        line_break = {
                                                disabled = !cfg.elements.line-break.enable;
                                        };

                                        character = {
                                                disabled = !cfg.elements.character.enable;
                                                success_symbol = cfg.elements.character.success;
                                                error_symbol = cfg.elements.character.error;
                                                vimcmd_symbol = cfg.elements.character.vimcmd.symbol;
                                                vimcmd_replace_one_symbol = cfg.elements.character.vimcmd.replace-one;
                                                vimcmd_replace_symbol = cfg.elements.character.vimcmd.replace;
                                                vimcmd_visual_symbol = cfg.elements.character.vimcmd.visual;
                                        };
                                }
                                
                                # Languages
                                (builtins.mapAttrs (name: symbol: {
                                        symbol = symbol;
                                        style = cfg.elements.languages.style;
                                        format = cfg.elements.languages.format;
                                }) cfg.elements.languages.symbols)

                                # Environments
                                (builtins.mapAttrs (name: format: {
                                        style = cfg.elements.languages.style;
                                        format = format;
                                }) cfg.elements.environments.formats)
                        ];
		};
	};
}
