{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "filebrowser";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name} docker stack";

    mounts = {
      nfs = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = [ ];
      };
    };

    fbData = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/filebrowser";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 30051;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nfs-utils ];
    boot.supportedFilesystems = [ "nfs" ];

    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];

    fileSystems = lib.mapAttrs' (name: value: {
      name = "/mnt/filebrowser/${name}";
      value = {
        device = value;
        fsType = "nfs";
      };
    }) cfg.mounts.nfs;

    users.users.filebrowser = {
      uid = 3002;
      isSystemUser = true;
      group = "filebrowser";
      home = cfg.fbData;
    };

    users.groups.filebrowser = {
      gid = 3003;
    };

    services.filebrowser = {
      enable = true;
      user = "filebrowser";
      group = "filebrowser";
      settings = {
        port = cfg.port;
        address = "0.0.0.0";
        root = "/mnt/filebrowser";
        database = "${cfg.fbData}/filebrowser.db";
        log = "/var/log/filebrowser/filebrowser.log";

        # Optional
        auth.method = "json";

        branding = {
          name = "Home drive";
          disableExternal = false;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.fbData} 0755 filebrowser filebrowser -"
    ];
  };
}
