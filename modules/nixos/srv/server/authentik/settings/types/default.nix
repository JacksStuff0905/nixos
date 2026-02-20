{ lib, authentikLib }:

{
  application = import ./application.nix { inherit lib authentikLib; };
  blueprint = import ./blueprint.nix { inherit lib; };
  provider = import ./provider.nix { inherit lib; };
  accessControl = import ./access-control.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
  group = import ./group.nix { inherit lib; };
  outpost = import ./outpost.nix { inherit lib; };
}
