{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "immich";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    port = lib.mkOption {
      type = lib.types.int;
      default = 2283;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    secret = {
      directory = lib.mkOption {
        type = lib.types.path;
      };
      oidc-client = lib.mkOption {
        type = lib.types.str;
        default = "immich-oidc-client-secret.age";
      };
    };

    group = {
      name = lib.mkOption {
        type = lib.types.str;
      };
    };

    mediaPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/immich";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.immich = {
      extraGroups = [ "${cfg.group.name}" ];
    };

    users.users.postgres = {
      extraGroups = [ "${cfg.group.name}" ];
    };

    systemd.tmpfiles.rules = [
      #"d ${cfg.mediaPath} 0775 ${cfg.user.name} ${cfg.group.name} -"
      "Z /var/lib/postgresql 0750 - - - -"
      #"d ${cfg.mediaPath} - - - - -"
      #"d ${cfg.mediaPath}/encoded-video 2775 - ${cfg.group.name} -"
      #"d ${cfg.mediaPath}/library 2775 - ${cfg.group.name} -"
      #"d ${cfg.mediaPath}/upload 2775 - ${cfg.group.name} -"
      #"d ${cfg.mediaPath}/thumbs 2775 - ${cfg.group.name} -"
      #"d ${cfg.mediaPath}/profile 2775 - ${cfg.group.name} -"
    ];

    environment.etc."tmpfiles.d/immich.conf".source = "/dev/null";

    age.secrets.immich-oidc-secret = {
      file = cfg.secret.directory + ("/" + cfg.secret.oidc-client);
      mode = "0640";
      owner = "root";
    };

    systemd.services.postgresql.serviceConfig = {
      StateDirectory = lib.mkForce "";
      #StateDirectoryMode = lib.mkForce "";
      ReadWritePaths = [ "/var/lib/postgresql" ];
      User = lib.mkForce "filebrowser";
    };

    systemd.services.immich-server = {
      after = [
        "remote-fs.target"
        "systemd-tmpfiles-setup.service"
      ];
      requires = [
        "remote-fs.target"
        "systemd-tmpfiles-setup.service"
      ];
      /*
        preStart = lib.mkBefore ''
          mkdir -p ${cfg.mediaPath}/encoded-video
          mkdir -p ${cfg.mediaPath}/library
          mkdir -p ${cfg.mediaPath}/upload
          mkdir -p ${cfg.mediaPath}/thumbs
          mkdir -p ${cfg.mediaPath}/profile
          mkdir -p ${cfg.mediaPath}/backups

          touch ${cfg.mediaPath}/encoded-video/.immich
          touch ${cfg.mediaPath}/library/.immich
          touch ${cfg.mediaPath}/upload/.immich
          touch ${cfg.mediaPath}/thumbs/.immich
          touch ${cfg.mediaPath}/profile/.immich
          touch ${cfg.mediaPath}/backups/.immich
        '';
      */

      serviceConfig = {
        ReadWritePaths = [ "${cfg.mediaPath}" ];
        StateDirectory = lib.mkForce "";

        UMask = lib.mkForce "0002";

        ProtectSystem = lib.mkForce false;
        ProtectHome = lib.mkForce false;
        PrivateTmp = lib.mkForce false;
        NoNewPrivileges = lib.mkForce false;
      };
    };

    systemd.services.immich-machine-learning = {
      after = [
        "remote-fs.target"
        "systemd-tmpfiles-setup.service"
      ];
      requires = [
        "remote-fs.target"
        "systemd-tmpfiles-setup.service"
      ];
      serviceConfig = {
        UMask = lib.mkForce "0002";
        StateDirectory = lib.mkForce "";

        ProtectSystem = lib.mkForce false;
        ProtectHome = lib.mkForce false;
        PrivateTmp = lib.mkForce false;
        NoNewPrivileges = lib.mkForce false;
      };
    };

    services.immich = {
      enable = true;
      port = cfg.port;
      host = "0.0.0.0";
      openFirewall = cfg.openFirewall;

      mediaLocation = cfg.mediaPath;

      environment = {
        NODE_TLS_REJECT_UNAUTHORIZED = "0";
      };

      settings = {
        machineLearning = {
          enable = false;
        };

        storageTemplate = {
          enabled = true;
          template = "{{owner}}/Photos/{{y}}/{{MM}}/{{filename}}";
        };

        oauth = {
          enabled = true;
          autoLaunch = true;
          autoRegister = true;
          buttonText = "Login with OAuth";
          clientId = "photos";
          clientSecret._secret = "${config.age.secrets.immich-oidc-secret.path}";
          defaultStorageQuota = null;
          issuerUrl = "https://auth.srv.lan/.well-known/openid-configuration";
          mobileOverrideEnabled = false;
          mobileRedirectUri = "";
          profileSigningAlgorithm = "none";
          roleClaim = "photos_role";
          scope = "openid email profile";
          signingAlgorithm = "RS256";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "photos_quota";
          timeout = 30000;
          tokenEndpointAuthMethod = "client_secret_basic";
        };
        passwordLogin = {
          enabled = true;
        };
      };
    };
  };
}
