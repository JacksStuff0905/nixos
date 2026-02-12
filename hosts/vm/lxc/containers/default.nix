{
  lib,
  util,
  inputs,
  system,
  nixpkgs,
}:

let
  file_to_not_import = [
    "default.nix"
  ];
in
(builtins.listToAttrs (
  builtins.map (f: {
    name = "ct-" + (builtins.baseNameOf f);
    value = (
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs util system;
        };

        modules = [
          (f + "/configuration.nix")
        ];
      }
    );
  }) (util.get-import-dir ./. file_to_not_import)
))
