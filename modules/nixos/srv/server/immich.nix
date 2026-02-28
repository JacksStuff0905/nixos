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

    secretFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.immich-secret = {
      file = cfg.secretFile;
      mode = "0640";
      owner = "root";
    };

    systemd.services.immich-server.serviceConfig.EnvironmentFile = config.age.secrets.immich-secret.path;

    services.immich = {
      enable = true;
      port = cfg.port;
      host = "0.0.0.0";
      openFirewall = cfg.openFirewall;

      settings = {
        oauth = {
          autoLaunch = true;
          autoRegister = true;
          buttonText = "Login with OAuth";
          clientId = "immich";
          clientSecret = "$OAUTH2_SECRET_immich";
          defaultStorageQuota = null;
          enabled = true;
          issuerUrl = "https://auth.srv.lan/application/o/immich/.well-known/openid-configuration";
          mobileOverrideEnabled = false;
          mobileRedirectUri = "";
          profileSigningAlgorithm = "none";
          roleClaim = "immich_role";
          scope = "openid email profile";
          signingAlgorithm = "RS256";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "immich_quota";
          timeout = 30000;
          tokenEndpointAuthMethod = "client_secret_post";
        };
        passwordLogin = {
          enabled = false;
        };
      };
    };
  };
}
