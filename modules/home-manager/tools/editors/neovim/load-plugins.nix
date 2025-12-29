{util, dir, vimPlugins, profile}:

let
	default-config = "";
	plugins-dir = ./plugins;

	parse-plugin =
		plugin:
			if (builtins.isString plugin) then
				[{
					plugin = vimPlugins.${plugin};
					config = default-config;
					type = "lua";
				}]
			else
				if ((plugin.profile or "") == profile) then
					[{
						config = plugin.config or default-config + "\n" + (plugin.keybinds or "");
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
			
	file-list = (util.get_import_dir plugins-dir ignore);
in
(builtins.concatMap import-file file-list)
