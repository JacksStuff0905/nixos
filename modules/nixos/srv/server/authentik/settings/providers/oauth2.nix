{ lib, authentikLib }:

with lib;

let
  inherit (authentikLib) find keyOf;

  # Only include scopes that exist by default in authentik
  defaultScopes = {
    "openid" = "goauthentik.io/providers/oauth2/scope-openid";
    "email" = "goauthentik.io/providers/oauth2/scope-email";
    "profile" = "goauthentik.io/providers/oauth2/scope-profile";
    "offline_access" = "goauthentik.io/providers/oauth2/scope-offline_access";
  };

in
{
  mkEntries =
    { app, providerConfig }:
    let
      clientId = if providerConfig.clientId != null then providerConfig.clientId else "ak-${app.slug}";

      # Filter to only valid default scopes
      validScopes = filter (s: hasAttr s defaultScopes) providerConfig.scopes;

      scopeMappings = map (
        scope:
        find "authentik_providers_oauth2.scopemapping" {
          managed = defaultScopes.${scope};
        }
      ) validScopes;

    in
    [
      {
        model = "authentik_providers_oauth2.oauth2provider";
        id = "provider";
        state = "present";
        identifiers.name = "${app.name} Provider";
        attrs = {
          name = "${app.name} Provider";
          authentication_flow = find "authentik_flows.flow" {
            slug = providerConfig.authenticationFlow;
          };
          authorization_flow = find "authentik_flows.flow" {
            slug = providerConfig.authorizationFlow;
          };
          # Add invalidation flow
          invalidation_flow = find "authentik_flows.flow" {
            slug = "default-provider-invalidation-flow";
          };
          client_type = providerConfig.clientType;
          client_id = clientId;
          # Make redirect_uris a list
          redirect_uris = providerConfig.redirectUris;
          access_token_validity = providerConfig.accessTokenValidity;
          refresh_token_validity = providerConfig.refreshTokenValidity;
          sub_mode = providerConfig.subMode;
          include_claims_in_id_token = providerConfig.includeClaimsInIdToken;
          issuer_mode = "per_provider";
          signing_key = find "authentik_crypto.certificatekeypair" {
            name = "authentik Self-signed Certificate";
          };
          property_mappings = scopeMappings;
        };
      }
    ];

  validate =
    { app, providerConfig }:
    let
      invalidScopes = filter (s: !hasAttr s defaultScopes) providerConfig.scopes;
    in
    (optional (
      providerConfig.redirectUris == [ ]
    ) "OAuth2 application '${app.name}' has no redirect URIs configured")
    ++ (optional (invalidScopes != [ ])
      "OAuth2 application '${app.name}' has invalid scopes: ${toString invalidScopes}. Valid scopes: ${toString (attrNames defaultScopes)}"
    );
}
