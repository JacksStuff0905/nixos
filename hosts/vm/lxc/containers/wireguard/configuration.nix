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
      wireguard = {
        enable = true;
        secret.directory = ../../../../../secrets/wireguard;
        publicKey = "P7okuk2RU9Cl9TbF2DrmfEOClwEV/RedhbeNqfZGJHs=";
      };
    };
  
    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
