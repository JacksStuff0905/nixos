{
  lib,
  util,
  inputs,
  system,
  nixpkgs,
  agenixModule,
  hosts,
  hostSpec,
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
          inherit inputs util system hosts;
        };

        modules = [
          (f + "/configuration.nix")
          (f + "/host.nix")
          agenixModule
          hostSpec
        ];
      }
    );
  }) (util.get-import-dir ./. file_to_not_import)
))
