{
  config,
  pkgs,
  inputs,
  util,
  lib,
  ...
}:
let
  blueprintPath = ./blueprints;

  file_to_not_import = [
  ];
in
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    networking.hostName = "ct-authentik";

    # Services
    srv.server = {
      authentik = {
        enable = true;
        secretsPath = ./secrets;
        blueprints = util.get-files-dir blueprintPath file_to_not_import;
      };
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
