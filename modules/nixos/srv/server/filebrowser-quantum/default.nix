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

  usersDir = "${cfg.fbRoot}/Users";

  # For the bind password, we'll use a secrets file


  types = with lib; {
    source = lib.types.submodule {
      options = with lib.types; {
        mounts = mkOption {
          type = attrsOf types.mount;
          default = { };
        };

        name = mkOption {
          type = str;
        };

        path = mkOption {
          type = str;
        };

        defaultEnabled = mkOption {
          type = bool;
          default = false;
        };
      };
    };

    mount = lib.types.submodule {
      options = with lib.types; {
        remote = mkOption {
          type = str;
        };

        type = mkOption {
          type = enum [
            "nfs"
            "cifs"
          ];
        };
      };
    };
  };
in
{
  imports = [
    inputs.agenix.nixosModules.default
    ./samba.nix
  ];

  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";

    authentik = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    secret = {
      directory = lib.mkOption {
        type = lib.types.path;
      };
    };

    sources = {
      userDrives = lib.mkOption {
        type = lib.types.str;
      };
      extra = lib.mkOption {
        type = lib.types.listOf types.source;
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

    fbRoot = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/filebrowser";
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

  config =
    let
      configFile = settingsFormat.generate "filebrowser.yaml" ({
        server = {
          listen = "0.0.0.0";
          port = cfg.port;
          baseURL = "/";
          database = "${cfg.fbData}/filebrowser.db";
          sources = [
            {
              path = usersDir;
              name = "my drive";
              config = {
                createUserDir = true;
                defaultUserScope = "/";
                defaultEnabled = true;
              };
            }
          ]
          ++ (builtins.map (s: {
            path = "${cfg.fbRoot}/${s.path}";
            name = "${s.name}";
            config = {
              defaultEnabled = s.defaultEnabled;
              disabled = false;
            };
          }) cfg.sources.extra);
        };

        auth.methods = {
          proxy = {
            enabled = true;
            createUser = true;
            header = "Remote-User";
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
    lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.nfs-utils
        pkgs.cifs-utils
      ];

      boot.supportedFilesystems = [ "nfs" ];

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        cfg.port
      ];

      fileSystems = lib.mkMerge [
        (lib.mergeAttrsList (
          builtins.map (
            s:
            (lib.mapAttrs' (name: value: {
              name = "${cfg.fbRoot}/${s.path}/${name}";
              value = {
                device = value.remote;
                fsType = value.type;
              };
            }) s.mounts)
          ) cfg.sources.extra
        ))

        ({
          usersDir = {
            device = cfg.sources.userDrives;
            fsType = "nfs";
          };
        })

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
        "d ${cfg.fbRoot} 0775 filebrowser filebrowser -"
        #"Z ${cfg.fbRoot} 0775 filebrowser filebrowser -"
        "d ${cfg.fbData} 0775 filebrowser filebrowser -"
      ];

      /*
        systemd.services.fix-user-permissions = {
          description = "Fix new user directory permissions";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "fix-perms" ''
              find ${cfg.fbRoot} -type d -exec chgrp -R filebrowser {} \;
              find ${cfg.fbRoot} -type d -exec chmod -R 775 {} \;
            '';
          };
        };

        systemd.paths.watch-user-directories = {
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = "${cfg.fbRoot}";
            Unit = "fix-user-permissions.service";
          };
        };
      */

      systemd.services.filebrowser-quantum = {
        description = "FileBrowser Quantum";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = "root";
          Group = "filebrowser";
          UMask = "0002";

          ProtectSystem = lib.mkForce false;
          ProtectHome = lib.mkForce false;
          PrivateTmp = lib.mkForce false;
          NoNewPrivileges = lib.mkForce false;

          #EnvironmentFile = config.age.secrets.filebrowser-oidc.path;
          ExecStart = "${lib.getExe pkgs.filebrowser-quantum} -c ${configFile}";
          Restart = "on-failure";
          #StateDirectory = "filebrowser";
          ReadWritePaths = [
            cfg.fbRoot
            cfg.fbData
          ];
        };
      };
    };
}
