{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  name = "filebrowser";

  cfg = config.srv.server."${name}";
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
    environment.systemPackages = [
      pkgs.nfs-utils
      pkgs.cifs-utils
    ];

    boot.supportedFilesystems = [ "nfs" ];

    networking.firewall.allowedTCPPorts = [
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

    systemd.services.filebrowser = {
      serviceConfig = {
        #EnvironmentFile = config.age.secrets.filebrowser-oidc.path;

        /*Environment = lib.mkIf cfg.authentik [
          "FB_AUTH_METHOD=oidc"
          "FB_OIDC_CLIENT_ID=fAQAxLoxnHhyxNd3vZxMz0ynpUtrSM8Z45cWpT8u"
          "FB_OIDC_AUTH_URL=https://auth.srv.lan/application/o/authorize/"
          "FB_OIDC_TOKEN_URL=https://auth.srv.lan/application/o/token/"
          "FB_OIDC_USERINFO_URL=https://auth.srv.lan/application/o/userinfo/"
          "FB_OIDC_REDIRECT_URL=https://drive.srv.lan/oauth2/callback"
          "FB_OIDC_SCOPE=openid profile email"
        ];*/
      };
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

        auth = {
          method = "proxy";
          header = "X-authentik-username";
        };

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
