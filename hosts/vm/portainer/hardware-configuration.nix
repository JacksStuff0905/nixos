{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  stacks-device = "192.168.10.6:/mnt/Main4TB/VM-Data/Portainer";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e27c5bdb-a271-4268-9e4d-0608e1ee3107";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E9C8-BB45";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # Mount stacks NFS
  fileSystems."/data/stacks" = {
    device = "${stacks-device}";
    fsType = "nfs";
    options = [ "nfsvers=4.2" ];
  };
  boot.supportedFilesystems = [ "nfs" ];

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
