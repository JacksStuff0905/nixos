{
  config,
  lib,
  pkgs,
  hosts,
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
      hostDevices = builtins.mapAttrs (n: h: { id = "${h.srv.syncthing.id}"; }) (
        lib.filterAttrs (n: h: (h.srv.syncthing.enable && h.srv.syncthing.id != cfg.id)) hosts
      );

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

      services.syncthing = {
        enable = true;
        openDefaultPorts = true;

        key = config.age.secrets.syncthing-key.path;
        cert = if cfg.certFile == null then cfg.cert else (builtins.readFile cfg.certFile);

        settings = {
          devices = lib.mkMerge [
            cfg.devices.extraDevices
            (lib.mkIf cfg.devices.includeHosts hostDevices)
          ];

          folders = builtins.mapAttrs (n: f: {
            path = f.path;
            devices = lib.mkMerge [
              f.devices.extraDevices
              (lib.mkIf f.devices.includeHosts (folderHosts "${n}"))
            ];
          }) cfg.folders;
        };
      };
    };
}
