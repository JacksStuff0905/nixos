{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.virtualization.proxmox.guest;
in
{
  options.virtualization.proxmox.guest = {
    enable = lib.mkEnableOption "proxmox guest tools";
  };

  config = lib.mkIf cfg.enable {
    services.qemuGuest.enable = true;

    services.spice-vdagentd.enable = true;

    boot.initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "virtio_blk"
      "virtio_net"
      "virtio_balloon"
      "virtio_console"
      "virtio_rng"
    ];

    services.xserver.videoDrivers = [
      "qxl"
      "modesetting"
    ];
  };
}
