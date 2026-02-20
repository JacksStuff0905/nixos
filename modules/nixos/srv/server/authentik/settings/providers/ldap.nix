{ lib, authentikLib }:

with lib;

let
  inherit (authentikLib) find;

in
{
  mkEntries =
    { app, providerConfig }:
    [
      {
        model = "authentik_providers_ldap.ldapprovider";
        id = "provider";
        state = "present";
        identifiers.name = "${app.name} Provider";
        attrs = {
          name = "${app.name} Provider";
          authorization_flow = find "authentik_flows.flow" {
            slug = providerConfig.authorizationFlow;
          };
          invalidation_flow = find "authentik_flows.flow" {
            slug = providerConfig.invalidationFlow;
          };
          base_dn = providerConfig.baseDn;
          bind_mode = "cached";
          search_mode = "cached";
        }
        // optionalAttrs (providerConfig.searchGroup != null) {
          search_group = find "authentik_core.group" {
            name = providerConfig.searchGroup;
          };
        };
      }
    ];

  validate =
    { app, providerConfig }:
    optional (providerConfig.baseDn == null) "LDAP application '${app.name}' requires a base DN";
}
