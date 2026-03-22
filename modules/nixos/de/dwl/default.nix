{
  config,
  pkgs,
  lib,
  ...
}:

{
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
}
