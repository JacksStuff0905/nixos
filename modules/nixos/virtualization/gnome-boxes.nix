{
  config,
  lib,
  pkgs,
  util,
  ...
}:

let
  cfg = config.virtualization.gnome-boxes;
in
{
  options.virtualization.gnome-boxes = {
    enable = lib.mkEnableOption "Enable gnome-boxes module";
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnome-boxes
      dnsmasq
    ];

    users.groups.libvirtd.members = cfg.users;
    users.groups.kvm.members = cfg.users;

    virtualisation = {
      libvirtd = {
        enable = true;

        # TPM
        qemu = {
          swtpm.enable = true;
          ovmf.packages = [ pkgs.OVMFFull.fd ];
        };
      };

      spiceUSBRedirection.enable = true;
    };
  };
}
