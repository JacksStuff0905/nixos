{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  name = "filebrowser-quantum";

  cfg = config.srv.server."${name}";

  settingsFormat = pkgs.formats.yaml { };
  configFile = settingsFormat.generate "filebrowser.yaml" ({
    server = {
      listen = "0.0.0.0";
      port = cfg.port;
      baseURL = "/";
      database = "/var/lib/filebrowser/filebrowser.db";
      sources = [
        {
          path = "/mnt/filebrowser";
          name = "drive";
          config = {
            createUserDir = true;
            defaultUserScope = "/";
          };
        }
      ];
    };

    auth.methods = {
      proxy = {
        enabled = true;
        createUser = true;
        header = "X-authentik-username";
      };
      password.enabled = false;
    };

    userDefaults.permissions = {
      admin = false;
      modify = true;
      share = true;
      delete = true;
      create = true;
      download = true;
    };
  });
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";

    authentik = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
    };

    mounts = {
      nfs = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = [ ];
      };
      smb = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = [ ];
      };
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = "Configuration for FileBrowser Quantum";
    };

    fbData = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/filebrowser";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 80;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nfs-utils
      pkgs.cifs-utils
    ];

    boot.supportedFilesystems = [ "nfs" ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.port
    ];

    fileSystems = lib.mkMerge [
      (lib.mapAttrs' (name: value: {
        name = "/mnt/filebrowser/${name}";
        value = {
          device = value;
          fsType = "nfs";
        };
      }) cfg.mounts.nfs)

      # WIP!!!
      /*
        (lib.mapAttrs' (name: value: {
          name = "/mnt/filebrowser/${name}";
          value = {
            device = value;
            fsType = "cifs";
            options = [
              "x-systemd.automount"
              "_netdev"
              "username=guest"
              "password="
              "uid=1000"
              "gid=100"
              "nofail"
              "noauto"
              "x-systemd.idle-timeout=60"
              "x-systemd.device-timeout=5s"
              "x-systemd.mount-timeout=5s"

              #,credentials=/etc/nixos/smb-secrets" ];
            ];
          };
        }) cfg.mounts.smb)
      */
    ];

    age.secrets.filebrowser-oidc = {
      file = cfg.secretFile;
      owner = "root";
      group = "filebrowser";
      mode = "0640";
    };

    users.users.filebrowser = {
      uid = 3002;
      isSystemUser = true;
      group = "filebrowser";
      home = cfg.fbData;
    };

    users.groups.filebrowser = {
      gid = 3003;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.fbData} 0755 filebrowser filebrowser -"
    ];

    systemd.services.filebrowser-quantum = {
      description = "FileBrowser Quantum";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "filebrowser";
        #EnvironmentFile = config.age.secrets.filebrowser-oidc.path;
        ExecStart = "${lib.getExe pkgs.filebrowser-quantum} -c ${configFile}";
        Restart = "on-failure";
        #StateDirectory = "filebrowser";
        ReadWritePaths = [
          "/mnt/filebrowser"
          cfg.fbData
        ];
      };
    };
  };
}
