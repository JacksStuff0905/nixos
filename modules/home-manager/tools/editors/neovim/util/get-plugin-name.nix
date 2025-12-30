{lib, plugin, package}:

let
      # 1. Generate a list of probable module names
      candidates = lib.unique (lib.flatten [
	# Strategy 0: User configured name, if it is set
	(lib.optional (plugin ? name) plugin.name)
      	
        # Strategy 1: Clean standard (telescope-nvim -> telescope)
        (lib.pipe plugin.plugin [ 
          (lib.removePrefix "nvim-") 
          (lib.removePrefix "vim-") 
          (lib.removeSuffix "-nvim") 
        ])

	# Strategy 2: More extreme cleanup
	(lib.pipe plugin.plugin [
		(lib.removeSuffix "-nvim")
		(lib.removePrefix "nvim-")
		(lib.removePrefix "vim-")
		(lib.removePrefix "lua-")
		(lib.removeSuffix "-lua")
		(lib.removeSuffix ".lua")
	])

        # Strategy 3: Replace dashes with underscores (nvim-tree -> nvim_tree)
        (lib.replaceStrings ["-"] ["_"] plugin.plugin)
        
        # Strategy 4: The original package name (some-library)
        plugin.plugin
      ]);

      # 2. The Verification Logic (Checks filesystem)
      checkPath = module:
        (builtins.pathExists "${package}/lua/${module}.lua") || 
        (builtins.pathExists "${package}/lua/${module}/init.lua");

      # 3. Find the first candidate that actually exists
      found = lib.findFirst checkPath null candidates;
in
      if found != null then 
        found 
      else 
        lib.warn ''

---------------------------------------------------
[Auto-Config Error] Could not determine module name
Package: ${plugin.plugin}

I checked inside the package for these modules:
${lib.concatMapStringsSep "\n" (c: " - require('${c}')") candidates}

None of them existed. 

Proceeding without creating a setup() function.
If the plugin requires one, please manually provide
the 'name' argument in plugin config.
---------------------------------------------------
        '' null

