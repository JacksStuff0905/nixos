{
  config,
  lib,
  pkgs,
  hosts,
  ...
}:

let
  cfg = config.srv.syncthing;
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
      secret = {
        enable = lib.mkOption {
          default = true;
          example = true;
          description = "Whether to enable secret folder.";
          type = lib.types.bool;
        };

        devices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
  };

  config =
    let
      hostDevices = builtins.mapAttrs (n: h: { id = "${h.srv.syncthing.id}"; }) (
        lib.filterAttrs (n: h: (h.srv.syncthing.enable && h.srv.syncthing.id != cfg.id)) hosts
      );
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

          folders = {
            "Secret" = lib.mkIf cfg.folders.secret.enable {
              path = "~/Secret";
              devices = cfg.folders.secret.devices;
            };
          };
        };
      };
    };
}
