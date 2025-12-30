{ lib, configs }:
let
  # 1. NEW HELPER: Recursively peel off 'mkIf' wrappers
  # If condition is true -> return content (and check again in case it's nested)
  # If condition is false -> return empty set {} (which effectively deletes it)
  unwrapMkIf = item:
    if (builtins.isAttrs item) && (item._type or "" == "if") then
      if item.condition then unwrapMkIf item.content else {}
    else
      item;

  # 2. Your merge logic (with the Recursive Fix included)
  mergeTwo = a: b:
    let
      # We must unwrap values deep inside the recursion too, 
      # just in case 'mkIf' is used inside attributes.
      valA = unwrapMkIf a;
      valB = unwrapMkIf b;

      # Standard intersection logic
      commonKeys = builtins.attrNames (builtins.intersectAttrs valA valB);
      
      resolve = k:
        let
          vA = valA.${k};
          vB = valB.${k};
        in
          if builtins.isString vA && builtins.isString vB then vA + "\n\n" + vB
          else if builtins.isList vA && builtins.isList vB then vA ++ vB
          # RECURSIVE CALL: We call mergeTwo so it keeps merging deep sets
          else if builtins.isAttrs vA && builtins.isAttrs vB then mergeTwo vA vB
          else vB;

      modifications = builtins.listToAttrs (map (k: { name = k; value = resolve k; }) commonKeys);
    in
      valA // valB // modifications;

  # 3. Clean the list before starting the fold
  # This handles the most common case: [ (mkIf true {...}) (mkIf false {...}) ]
  cleanConfigs = map unwrapMkIf configs;

in
  # Run the merge
  builtins.foldl' mergeTwo {} cleanConfigs
