{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "wireguard";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";

    secret = {
      directory = lib.mkOption {
        type = lib.types.path;
      };

      firezone-admin-password = lib.mkOption {
        type = lib.types.str;
        default = "firezone-admin-password.age";
      };

      firezone-oidc-client-secret = lib.mkOption {
        type = lib.types.str;
        default = "firezone-oidc-client-secret.age";
      };

      firezone-db-encryption-key = lib.mkOption {
        type = lib.types.str;
        default = "firezone-db-encryption-key.age";
      };
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      firezone-admin-password = {
        file = cfg.secret.directory + ("/" + cfg.secret.firezone-admin-password);
        owner = "firezone";
        group = "firezone";
      };

      firezone-oidc-client-secret = {
        file = cfg.secret.directory + ("/" + cfg.secret.firezone-oidc-client-secret);
        owner = "firezone";
        group = "firezone";
      };

      firezone-db-encryption-key = {
        file = cfg.secret.directory + ("/" + cfg.secret.firezone-db-encryption-key);
        owner = "firezone";
        group = "firezone";
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "firezone" ];
      ensureUsers = [
        {
          name = "firezone";
          ensureDBOwnership = true;
        }
      ];
    };

    services.firezone.server = {
      enable = true;

      enableLocalDB = true;

      settings = {
        # This is the external URL where users will access Firezone
        # Must match the redirect_uri in Authelia config
        EXTERNAL_URL = "https://vpn.srv.lan";

        # Database
        DATABASE_HOST = "/run/postgresql";
        DATABASE_NAME = "firezone";
        DATABASE_USER = "firezone";

        # Admin
        DEFAULT_ADMIN_EMAIL = "admin@example.com";

        # WireGuard
        WIREGUARD_PORT = "51820";
        WIREGUARD_IPV4_NETWORK = "192.168.11.0/24";
        WIREGUARD_ALLOWED_IPS = "10.0.0.0/8,192.168.0.0/16";
        WIREGUARD_DNS = "192.168.10.5";
        WIREGUARD_MTU = "1280";
        WIREGUARD_PERSISTENT_KEEPALIVE = "25";

        # OIDC - Authelia
        AUTH_OIDC_ENABLED = "true";
        AUTH_OIDC_CLIENT_ID = "vpn";
        AUTH_OIDC_DISCOVERY_DOCUMENT_URI = "https://auth.srv.lan/.well-known/openid-configuration";
        AUTH_OIDC_REDIRECT_URI = "https://vpn.srv.lan/auth/oidc/firezone/callback/";
        AUTH_OIDC_RESPONSE_TYPE = "code";
        AUTH_OIDC_SCOPE = "openid email profile";
        AUTH_OIDC_LABEL = "Sign in with Authelia";
        AUTH_OIDC_AUTO_CREATE_USERS = "true";

        # Disable local authentication (optional - OIDC only)
        # LOCAL_AUTH_ENABLED = "false";
      };

      # Secret settings - maps env var name to file path
      settingsSecret = {
        DEFAULT_ADMIN_PASSWORD = config.age.secrets.firezone-admin-password.path;
        AUTH_OIDC_CLIENT_SECRET = config.age.secrets.firezone-oidc-client-secret.path;
        SECRET_KEY_BASE = config.age.secrets.firezone-db-encryption-key.path;
      };
    };

    networking.firewall = {
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [
        80
        443
      ];
    };
  };
}
