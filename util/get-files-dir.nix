{ lib, dir, ignore, self}:

let
  walk = path: relPath:
    lib.flatten (
      lib.pipe path [
        builtins.readDir
        
        (lib.mapAttrsToList (name: type: 
          let
            thisRelPath = if relPath == "" then name else "${relPath}/${name}";
            
            thisAbsPath = path + "/${name}";
          in
            if lib.elem thisRelPath ignore then 
              []
            
            else if type == "directory" then
              walk thisAbsPath thisRelPath
              
            else if (type == "regular" || type == "symlink") then
              [ thisAbsPath ]
              
            else 
              []
        ))
      ]
    );
in
  walk dir ""
