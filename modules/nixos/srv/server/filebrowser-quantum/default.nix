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

  cacheDir = "/tmp";

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

      # Temporary filebrowser-quantum overlay to install v1.3.0
      # Can be removed once said version gets packaged to nixpkgs
      nixpkgs.overlays = [
        (
          final: prev:
          let
            version = "1.3.0-stable";

            src = prev.fetchFromGitHub {
              owner = "gtsteffaniak";
              repo = "filebrowser";
              rev = "v${version}";
              hash = "sha256-U2J5ilP6fq7vsQ5qjLBvulzatAndlr13NRDF1KLoCWs=";
            };

            newFrontend = prev.buildNpmPackage {
              pname = "filebrowser-quantum-frontend";
              inherit version src;

              sourceRoot = "${src.name}/frontend";

              npmDepsHash = "sha256-926Wey0OyIKSiY0GBbzqh4pooB2Oz6QoRJs/SUUvlRE=";

              buildPhase = ''
                runHook preBuild
                npm run build:docker
                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall
                mkdir -p $out
                cp -r dist/* $out
                runHook postInstall
              '';
            };
          in
          {
            filebrowser-quantum = prev.filebrowser-quantum.overrideAttrs (oldAttrs: rec {
              inherit version src;

              sourceRoot = "${src.name}/backend";

              vendorHash = "sha256-+IZ5sr7/nLgjEa2xxTbOdNQzh0DsffaAWWATw/45yyU=";

              preBuild = ''
                mkdir -p http/embed
                cp -r ${newFrontend}/* http/embed/
              '';
            });
          }
        )
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
          "${cfg.fbRoot}/Users" = {
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
        "d ${cacheDir} 0775 filebrowser filebrowser -"
        "Z ${cacheDir} 0775 filebrowser filebrowser -"
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
          User = "filebrowser";
          Group = "filebrowser";
          UMask = "0002";

          ProtectSystem = lib.mkForce false;
          ProtectHome = lib.mkForce false;
          PrivateTmp = lib.mkForce false;
          NoNewPrivileges = lib.mkForce false;
          AmbientCapabilities = "CAP_NET_BIND_SERVICE";
          CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";

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
