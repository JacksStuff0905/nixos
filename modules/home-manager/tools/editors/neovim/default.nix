{config, lib, pkgs, ...}:

let
  profile = config.tools.editors.neovim.profile;
in 
{
	options.tools.editors.neovim = {
		enable = lib.mkEnableOption "Enable neovim module";
		profile = lib.mkOption {
			type = lib.types.enum [ "basic" "full" ];
			default = "basic";
			description = "What neovim config profile to use, one of: basic, full";
		};
	};

	config = lib.mkIf config.tools.editors.neovim.enable {
		programs.neovim = lib.mkMerge [
			# Shared configs
			({
				enable = true;
				defaultEditor = true;
			})

			# Basic-only configs
			(lib.mkIf (profile == "basic") {

			})

			# Full-only configs
			(lib.mkIf (profile == "full") {
				withNodeJs = true;
				plugins = with pkgs.vimPlugins; [
				    #lazy-nvim
				];
			})
		];

		home.packages = with pkgs; lib.mkMerge [
			# Shared dependencies
			([])
			
			# Basic-only dependencies
			(lib.mkIf (profile == "basic") [])

			# Full-only dependencies
			(lib.mkIf (profile == "full") [
				# For treesitter
				gcc

				python3
				perl
				curl
				unzip
				ruby
				lua
				luarocks

				pkg-config

				ollama

				ripgrep
				fd
			])
		];

		#xdg.configFile."nvim" = {
		#	recursive = true;
		#	source = ../../../../config/nvim;
		#};

	};
}
