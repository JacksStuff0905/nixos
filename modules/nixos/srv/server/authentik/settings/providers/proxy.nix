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
        model = "authentik_providers_proxy.proxyprovider";
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
          external_host = providerConfig.externalHost;
          internal_host = providerConfig.internalHost;
          mode = providerConfig.mode;
          internal_host_ssl_validation = true;
          intercept_header_auth = true;
        };
      }
    ];

  validate =
    { app, providerConfig }:
    (optional (
      providerConfig.externalHost == null
    ) "Proxy application '${app.name}' requires an external host")
    ++ (optional (
      providerConfig.internalHost == null && providerConfig.mode == "proxy"
    ) "Proxy application '${app.name}' in proxy mode requires an internal host");
}
