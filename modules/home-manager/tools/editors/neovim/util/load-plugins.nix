{util, dir, vimPlugins, vimUtils, profile, lib, print}:

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

	default-config = plugin: generate-setup (get-name plugin) "";

	get-name =
		plugin:
      if (!(plugin ? plugin) || (plugin.plugin == null) || (plugin.plugin == "")) then
        null
      else
        if (plugin ? dir) then
          plugin.plugin
        else
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
						config = (default-config { inherit plugin; });
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
                  (default-config plugin);
          in
          if (plugin ? dir) then
            let
              dependencies = (builtins.concatMap load-plugin plugin.dependencies);
            in 
            [{
              plugin = (vimUtils.buildVimPlugin {
                name = plugin.plugin or plugin.dir;
                src = plugin.dir;
                dependencies = (builtins.map (plugin: plugin.plugin) dependencies);
              });

              type = "lua";
              config = (opts) + "\n" +
                 (config) + "\n" +
                 (plugin.keybinds or "") + "\n\n\n" +
                 (lib.strings.concatStringsSep "\n\n" (builtins.map (plugin: plugin.config) dependencies));
            }]
          else
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
      let 
        parsed = (parse-plugin plugin);
      in
			if ((plugin.profile or "") == profile) then
				if (!(builtins.isString plugin) && (plugin ? dependencies)) then
          if (plugin ? dir) then
            parsed
          else
            ((builtins.concatMap parse-plugin plugin.dependencies) ++ parsed)
				else
					parsed
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
  result = builtins.concatMap import-file file-list;
in
if print then
(builtins.trace ''
                 Loaded Neovim Plugins:
-------------------------------------------------------
${(lib.generators.toPretty { multiline = true; } result)}
-------------------------------------------------------
'' result)
else
result
