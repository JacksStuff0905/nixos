{
  config,
  lib,
  pkgs,
  hosts,
  options,
  ...
}:

let
  cfg = config.srv.syncthing;

  types = {
    folder =
      with lib;
      lib.types.submodule {
        options = with lib.types; {
          enable = mkOption {
            default = false;
            example = true;
            description = "Whether to enable this folder";
            type = bool;
          };

          path = mkOption {
            type = str;
          };

          versioning = lib.mkOption {
            type = attrs;
            default = {
              type = "simple";
              params.keep = "3";
            };
          };

          devices = {
            includeHosts = mkOption {
              type = bool;
              default = true;
            };
            extraDevices = mkOption {
              type = nullOr (listOf str);
              default = null;
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
      default = config.host.username;
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "syncthing";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = config.host.home;
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
        type = types.folder;
        default = {
          enable = true;
          path = "~/Secret";
        };
      };
    };
  };

  config =
    let
      hostDevices = builtins.mapAttrs (n: h: {
        id = "${h.srv.syncthing.id}";
      }) (lib.filterAttrs (n: h: (h.srv.syncthing.enable && h.srv.syncthing.id != cfg.id)) hosts);

      folderHosts =
        f:
        (builtins.attrNames (
          lib.filterAttrs (
            n: h:
            (
              h.srv.syncthing.enable
              && h.srv.syncthing.id != cfg.id
              && h.srv.syncthing.folders ? "${f}"
              && h.srv.syncthing.folders."${f}".enable
            )
          ) hosts
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
              (
                if f.devices.extraDevices == null then
                  (builtins.attrNames cfg.devices.extraDevices)
                else
                  f.devices.extraDevices
              )
              (lib.mkIf f.devices.includeHosts (folderHosts "${n}"))
            ];
          }) cfg.folders;
        };
      };
    };
}
