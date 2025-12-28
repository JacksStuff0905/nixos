{config, lib, pkgs, ...}:

{
	options.tools.cli.fastfetch = {
		enable = lib.mkEnableOption "Enable fastfetch module";
	};

	config = lib.mkIf config.tools.cli.fastfetch.enable {
		programs.fastfetch = {
			enable = true;
			settings = {
			  schema = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
			  /*"logo": {
			    "source": "~/.config/fastfetch/logo.txt",
			    "type": "file"   
			  },*/
			  modules = [
			    "break"
			    "break"
			    "title"
			    "separator"
			    "packages"
			    "break"
			    "shell"
			    "break"
			    "display"
			    "break"
			    "de"
			    "terminal"
			    "break"
			    "cpu"
			    "gpu"
			    "break"
			    "memory"
			    "disk"
			    
			    "colors"
			  ];
			};
		};
	};
}
