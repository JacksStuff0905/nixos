{config, lib, pkgs, util, ...}:

let
  profile = config.tools.editors.neovim.profile;
  plugins-dir = ./plugins;
  load-plugins = profile: (import ./util/load-plugins.nix {
    inherit lib;
    inherit util;
    dir = plugins-dir;
    vimPlugins = pkgs.vimPlugins;
    vimUtils = pkgs.vimUtils;
    inherit profile;
    print = config.tools.editors.neovim.debug.print-plugins;
  });
  combine-configs = configs: (import ./util/combine-configs.nix {
    inherit configs;
    inherit lib;
  });
in 
{
	options.tools.editors.neovim = {
		enable = lib.mkEnableOption "Enable neovim module";
		profile = lib.mkOption {
			type = lib.types.enum [ "basic" "full" ];
			default = "basic";
			description = "What neovim config profile to use, one of: basic, full";
		};
		debug = {
			print-config = lib.mkEnableOption "Show the full neovim config when building";
      print-plugins = lib.mkEnableOption "Show the loaded neovim plugin list when building";
	};
	};

	config = let
		neovim-conf = (combine-configs [
			# Shared configs
			({
				enable = true;
				defaultEditor = true;
				plugins = (load-plugins "");
				
				extraConfig = ''
lua << EOF

--[[ PRE-PROCESSING ]]--
-- Set the package namespace to use the conf/modules directory, necessary for require()
package.path = package.path .. ";" .. "${./conf/lua}" .. "/?.lua"

--[[ MAIN CONFIG ]]--
				'' + "\n"
				+ (lib.fileContents ./conf/init.lua) + "\n";
			})

			# Basic-only configs
			(lib.mkIf (profile == "basic") {
				plugins = (load-plugins "basic");
				extraConfig = ''

--[[ BASIC-ONLY CONFIG ]]--
				'' + "\n"
				+ (lib.fileContents ./conf/basic.lua) + "\n";
			})

			# Full-only configs
			(lib.mkIf (profile == "full") {
				withNodeJs = true;
				plugins = (load-plugins "full");
				extraConfig = ''

--[[ FULL-ONLY CONFIG ]]--
				'' + "\n"
				+ (lib.fileContents ./conf/full.lua) + "\n";
			})

      ({
        extraConfig = "\n\nEOF";
      })
		]);
	in
	{
		programs.neovim = 
			lib.mkIf config.tools.editors.neovim.enable
				(if config.tools.editors.neovim.debug.print-config then
					(builtins.trace ''
						Generated Neovim Config
	---------------------------------------------------------------------------------------------------------
	${neovim-conf.extraConfig}
	---------------------------------------------------------------------------------------------------------
					'' neovim-conf)
				else
					neovim-conf);


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
