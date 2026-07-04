{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
    # Inherit config from master LXC
    ../adguard1/configuration.nix
  ];

  config = {
    # Services
    srv.server = {
      keepalived.master.enable = lib.mkForce false;
    };
  };
}
