{
  config,
  lib,
  pkgs,
  ...
}:

let
  authentikLib = import ./lib { inherit lib pkgs; };
  types' = import ./types {
    inherit lib;
    authentikLib = authentikLib;
  };

in
{
  imports = [
    ./options.nix
    ./deploy.nix
    ./cleanup.nix
  ];

  config = lib.mkIf config.srv.server.authentik.enable (
    let
      cfg = config.srv.server.authentik;

      blueprintGen = import ./blueprints {
        inherit lib pkgs authentikLib;
        inherit (cfg)
          applications
          blueprints
          users
          groups
          outposts
          ;
      };
    in
    {
      _module.args = {
        inherit authentikLib;
        authentikTypes = types';
      };

      srv.server.authentik.generatedPath = blueprintGen.blueprintsDir;
      warnings = blueprintGen.warnings;
      assertions = blueprintGen.assertions;
    }
  );
}
