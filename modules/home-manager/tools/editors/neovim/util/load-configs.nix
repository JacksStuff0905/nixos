{lib, dir, util, profile}:

let
	ignore = [

	];

	files = util.get-files-dir dir ignore;

	parse-config =
		config:
			if ((config.profile or "") == profile) then
				if (builtins.isString config) then
					[{
						config = config;
					}]
				else
			else
				[];
	
	import-config =
		file:
			parse-config file;

in 
(builtins.concatMap)
