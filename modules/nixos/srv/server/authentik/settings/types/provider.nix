{ lib }:

with lib;

types.submodule {
  options = {
    type = mkOption {
      type = types.enum [
        "oauth2"
        "saml"
        "proxy"
        "ldap"
      ];
      default = "oauth2";
      description = "Provider type";
    };

    # === Common options ===
    authenticationFlow = mkOption {
      type = types.str;
      default = "default-authentication-flow";
      description = "Authentication flow slug";
    };

    authorizationFlow = mkOption {
      type = types.str;
      default = "default-provider-authorization-explicit-consent";
      description = "Authorization flow slug";
    };

    invalidationFlow = mkOption {
      type = types.str;
      default = "default-provider-invalidation-flow";
      description = "Invalidation flow slug";
    };

    propertyMappings = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional property mapping names to include";
    };

    # === OAuth2 ===
    clientId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "OAuth2 client ID (auto-generated from slug if null)";
    };

    clientSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing OAuth2 client secret";
    };

    clientType = mkOption {
      type = types.enum [
        "confidential"
        "public"
      ];
      default = "confidential";
      description = "OAuth2 client type";
    };

    redirectUris = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "OAuth2 redirect URIs";
    };

    scopes = mkOption {
      type = types.listOf types.str;
      default = [
        "openid"
        "email"
        "profile"
      ];
      description = "OAuth2 scopes";
    };

    accessTokenValidity = mkOption {
      type = types.str;
      default = "minutes=10";
      description = "Access token validity";
    };

    refreshTokenValidity = mkOption {
      type = types.str;
      default = "days=30";
      description = "Refresh token validity";
    };

    subMode = mkOption {
      type = types.enum [
        "hashed_user_id"
        "user_id"
        "user_uuid"
        "user_username"
        "user_email"
      ];
      default = "hashed_user_id";
      description = "Subject mode for tokens";
    };

    includeClaimsInIdToken = mkOption {
      type = types.bool;
      default = true;
      description = "Include claims in ID token";
    };

    # === SAML ===
    acsUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SAML ACS URL";
    };

    audience = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SAML audience";
    };

    issuer = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SAML issuer";
    };

    spBinding = mkOption {
      type = types.enum [
        "post"
        "redirect"
      ];
      default = "post";
      description = "SAML SP binding";
    };

    # === Proxy ===
    externalHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Proxy external host";
    };

    internalHost = mkOption {
      type = types.nullOr types.str;
      default = "";
      description = "Proxy internal host";
    };

    mode = mkOption {
      type = types.enum [
        "proxy"
        "forward_single"
        "forward_domain"
      ];
      default = "proxy";
      description = "Proxy mode";
    };

    # === LDAP ===
    baseDn = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LDAP base DN";
    };

    searchGroup = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "LDAP search group";
    };
  };
}
