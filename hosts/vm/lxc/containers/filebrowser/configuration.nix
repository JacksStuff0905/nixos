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
    networking.hostName = "ct-filebrowser";

    # Services
    srv.server = {
      filebrowser = {
        enable = true;
        mounts.nfs = {
          "VM-Data/Data" = "192.168.10.6:/mnt/Main4TB/VM-Data/Data";
          "VM-Data/Proxmox" = "192.168.10.6:/mnt/Main4TB/VM-Data/Proxmox";
        };
      };
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
