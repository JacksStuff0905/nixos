{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    # Services
    srv.server = {
      jellyfin = {
        enable = true;
      };
    };
  
    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
