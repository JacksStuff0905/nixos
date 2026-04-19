{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.de.dwl;
in
{
  options.de.dwl = {
    enable = lib.mkEnableOption "dwl";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        dwl = prev.dwl.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
          ];

          postPatch = (oldAttrs.postPatch or "") + ''
            cp ${./src/config.h} config.h
          '';

          buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
          ];
        });
      })
    ];
  };
}
