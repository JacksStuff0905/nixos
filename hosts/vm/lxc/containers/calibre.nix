{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../base-lxc.nix
    ../../../../modules/nixos/dev-utils
    ../../../../modules/nixos/sh
    ../../../../modules/nixos/srv
  ];

  config = {
    networking.hostName = "CTCalibre";

    # Services
    srv.server = {
      calibre.enable = true;
    };

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
