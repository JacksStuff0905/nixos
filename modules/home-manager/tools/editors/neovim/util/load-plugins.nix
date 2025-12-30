{util, dir, vimPlugins, profile, lib, ...}:

let
	plugins-dir = ../plugins;


	generate-setup =
		name: opts-str: 
		if (name == null) then
			""
		else
			''
				local ok, mod = pcall(require, "${name}")
				if ok and type(mod) == "table" and type(mod.setup) == "function" then
					mod.setup({
						${opts-str}
					})
				end
			'';

	default-config = plugin: generate-setup (get-name {inherit plugin;}) "";

	get-name =
		plugin:
			(import ./get-plugin-name.nix {inherit lib; inherit plugin; package = vimPlugins.${plugin.plugin}; });

	parse-opts =
		plugin:
			if (plugin ? opts) then
					generate-setup (get-name plugin) plugin.opts
			else
				"";

	parse-plugin =
		plugin:
			if ((plugin.profile or "") == profile) then
				if (builtins.isString plugin) then
					[{
						plugin = vimPlugins.${plugin};
						config = (default-config plugin);
						type = "lua";
					}]
				else
					let
						opts = (parse-opts plugin);
						config =
							if (plugin ? config) then
								plugin.config
							else
								if (opts != "") then
									""
								else
									(default-config plugin.plugin);
					in
					[{
						config = (opts) + "\n" +
							 (config) + "\n" +
							 (plugin.keybinds or "");
						type = "lua";
						plugin = vimPlugins.${plugin.plugin};
					}]
			else
				[];

	load-plugin =
		plugin:
			if ((plugin.profile or "") == profile) then
				if (!(builtins.isString plugin) && (plugin ? dependencies)) then
					((builtins.concatMap parse-plugin plugin.dependencies) ++ (parse-plugin plugin))
				else
					(parse-plugin plugin)
			else
				[];
				

	import-file = 
		file:
			let
				plugins = import file;
			in
			(builtins.concatMap load-plugin plugins);

	
	ignore = [
		"lua"
	];
			
	file-list = (util.get-import-dir plugins-dir ignore);
in
(builtins.concatMap import-file file-list)
