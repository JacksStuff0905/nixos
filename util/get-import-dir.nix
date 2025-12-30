{ lib, dir, ignore, self}:
    lib.flatten (
      lib.pipe dir [
	builtins.readDir
	(lib.filterAttrs (name: type: type == "directory" || lib.hasSuffix ".nix" name))
	(lib.filterAttrs (name: _: !(lib.elem name ignore)))
	(lib.mapAttrsToList (
	  name: type: dir + ("/" + name)
	))
      ]
)
