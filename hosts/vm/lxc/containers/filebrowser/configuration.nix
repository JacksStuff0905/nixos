{
  config,
  pkgs,
  inputs,
  ...
}:
let
  nasIP = "192.168.10.6";
  nfsPath = "/mnt/Main4TB";
in
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
        mounts = {
          nfs = {
            "VM-Data/Data" = "${nasIP}:${nfsPath}/VM-Data/Data";
            "VM-Data/Proxmox" = "${nasIP}:${nfsPath}/VM-Data/Proxmox";
          };
          smb = {
            #"Backups" = "//${nasIP}/Backups";
            #"Files/Games" = "//${nasIP}/Games";
          };
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
