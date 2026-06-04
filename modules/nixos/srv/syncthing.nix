{
  config,
  lib,
  pkgs,
  common,
  ...
}:

let
  cfg = config.srv.syncthing;

  types = {
    mkFolder =
      with lib;
      {
        enable ? false,
        path ? "",
        versioning ? {
          type = "simple";
          params.keep = "3";
        },
      }:
      lib.types.submodule {
        options = with lib.types; {
          enable = mkOption {
            example = true;
            description = "Whether to enable this folder";
            type = bool;
            default = enable;
          };

          path = mkOption {
            type = str;
            default = path;
          };

          versioning = lib.mkOption {
            type = attrs;
            default = versioning;
          };

          devices = {
            includeHosts = mkOption {
              type = bool;
              default = true;
            };
            extraDevices = mkOption {
              type = listOf str;
              default = [ ];
            };
          };
        };
      };
  };
in
{
  options.srv.syncthing = {
    enable = lib.mkEnableOption "Enable syncthing module";

    id = lib.mkOption {
      type = lib.types.str;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = config.host.user.name;
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "syncthing";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = config.host.user.home;
    };

    keySecret = lib.mkOption {
      type = lib.types.path;
    };

    cert = lib.mkOption {
      type = lib.types.str;
      default = "";
    };

    certFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    devices = {
      includeHosts = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      extraDevices = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
      };
    };

    folders = {
      secret = lib.mkOption {
        type = types.mkFolder {
          enable = true;
          path = "~/Secret";
        };
        default = { };
      };

      projects = lib.mkOption {
        type = types.mkFolder {
          enable = false;
        };
        default = { };
      };

      calibreLibrary = lib.mkOption {
        type = types.mkFolder {
          enable = false;
        };
        default = { };
      };
    };
  };

  config =
    let
      hostDevices = lib.mapAttrs' (n: h: {
        name = "${h.host.hostName or n}";
        value = {
          id = "${h.srv.syncthing.id}";
        };
      }) (lib.filterAttrs (n: h: (h.srv.syncthing.enable && h.srv.syncthing.id != cfg.id)) common.nixosHosts);

      folderHosts =
        f:
        (lib.mapAttrsToList (n: h: h.host.hostName) (
          lib.filterAttrs (
            n: h:
            (
              let
                folders = h.srv.syncthing.folders;
              in
              h.srv.syncthing.enable
              && h.srv.syncthing.id != cfg.id
              && folders ? "${f}"
              && folders."${f}" ? enable
              && folders."${f}".enable
            )
          ) common.nixosHosts
        ));
    in
    lib.mkIf cfg.enable {
      age.secrets.syncthing-key.rekeyFile = cfg.keySecret;

      users.users."${cfg.user}".extraGroups = [ cfg.group ];

      services.syncthing = {
        enable = true;
        openDefaultPorts = true;

        key = config.age.secrets.syncthing-key.path;
        cert =
          if cfg.certFile == null then
            "${
              (builtins.toFile "cert.pem" (
                lib.strings.trim (builtins.replaceStrings [ "\t" "\r" ] [ "" "" ] cfg.cert) + "\n"
              ))
            }"
          else
            cfg.certFile;

        dataDir = cfg.dataDir;
        user = cfg.user;
        group = cfg.group;

        settings = {
          devices = lib.mkMerge [
            cfg.devices.extraDevices
            (lib.mkIf cfg.devices.includeHosts hostDevices)
          ];

          folders = builtins.mapAttrs (n: f: {
            path = f.path;
            versioning = f.versioning;
            devices = lib.mkMerge [
              f.devices.extraDevices
              (lib.mkIf f.devices.includeHosts (folderHosts "${n}"))
            ];
          }) (lib.filterAttrs (n: f: f.enable) cfg.folders);
        };
      };
    };
}
