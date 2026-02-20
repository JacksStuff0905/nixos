{ lib, authentikLib }:

with lib;

let
  inherit (authentikLib) find;

in
{
  mkEntries =
    { app, providerConfig }:
    let
      audience =
        if providerConfig.audience != null then providerConfig.audience else providerConfig.acsUrl;

    in
    [
      {
        model = "authentik_providers_saml.samlprovider";
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
          invalidation_flow = find "authentik_flows.flow" {
            slug = providerConfig.invalidationFlow;
          };
          acs_url = providerConfig.acsUrl;
          audience = audience;
          issuer = providerConfig.issuer or "https://authentik/application/saml/${app.slug}/";
          sp_binding = providerConfig.spBinding;
          signing_kp = find "authentik_crypto.certificatekeypair" {
            name = "authentik Self-signed Certificate";
          };
          name_id_mapping = find "authentik_providers_saml.samlpropertymapping" {
            managed = "goauthentik.io/providers/saml/email";
          };
          digest_algorithm = "http://www.w3.org/2001/04/xmlenc#sha256";
          signature_algorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";
          assertion_valid_not_before = "minutes=-5";
          assertion_valid_not_on_or_after = "minutes=5";
          session_valid_not_on_or_after = "hours=8";
        };
      }
    ];

  validate =
    { app, providerConfig }:
    optional (providerConfig.acsUrl == null) "SAML application '${app.name}' requires an ACS URL";
}
