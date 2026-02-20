{ lib, pkgs }:

rec {
  tags = import ./tags.nix { inherit lib; };
  yaml = import ./yaml.nix { inherit lib pkgs tags; };
  utils = import ./utils.nix { inherit lib; };

  # Re-export commonly used functions
  inherit (tags)
    find
    keyOf
    context
    env
    condition
    if_
    format
    ;
  inherit (yaml) mkBlueprint toYAMLWithTags;
  inherit (utils) mkProvider mkApplication;
}
