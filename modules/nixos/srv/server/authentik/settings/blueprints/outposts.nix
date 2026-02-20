{
  lib,
  pkgs,
  authentikLib,
}:

with lib;

let
  inherit (authentikLib) find keyOf;

  providerModel =
    type:
    {
      proxy = "authentik_providers_proxy.proxyprovider";
      ldap = "authentik_providers_ldap.ldapprovider";
      radius = "authentik_providers_radius.radiusprovider";
      rac = "authentik_providers_rac.racprovider";
    }
    .${type} or (throw "Unknown outpost type: ${type}");

in
{
  generateOutpostEntries =
    { outposts, applications }:
    let
      enabledOutposts = filterAttrs (n: v: v.enable) outposts;
      enabledApps = filterAttrs (n: v: v.enable) applications;

      outpostApps = mapAttrs (
        outpostName: outpost:
        let
          explicitApps = outpost.applications;
          referencingApps = attrNames (filterAttrs (appName: app: app.outpost == outpostName) enabledApps);
        in
        unique (explicitApps ++ referencingApps)
      ) enabledOutposts;

      outpostsWithProviders = filterAttrs (
        outpostName: outpost:
        let
          appNames = outpostApps.${outpostName} or [ ];
          validAppNames = filter (appName: hasAttr appName enabledApps) appNames;
        in
        length validAppNames > 0
      ) enabledOutposts;

    in
    mapAttrsToList (
      outpostName: outpost:
      let
        appNames = outpostApps.${outpostName} or [ ];

        providerRefs = map (
          appName:
          let
            app = enabledApps.${appName} or null;
            appDisplayName = if app != null then app.name else appName;
          in
          find (providerModel outpost.type) {
            name = "${appDisplayName} Provider";
          }
        ) (filter (appName: hasAttr appName enabledApps) appNames);

        # Default config for embedded outpost
        defaultConfig = {
          authentik_host = outpost.config.authentik_host or "";
          authentik_host_insecure = outpost.config.authentik_host_insecure or false;
          authentik_host_browser = outpost.config.authentik_host_browser or "";
          log_level = outpost.config.log_level or "info";
          object_naming_template = outpost.config.object_naming_template or "ak-outpost-%(name)s";
        };

      in
      {
        model = "authentik_outposts.outpost";
        id = "outpost-${outpostName}";
        state = "present";
        identifiers.name = outpost.name;
        attrs = {
          name = outpost.name;
          type = outpost.type;
          config = defaultConfig // outpost.config;
          providers = providerRefs;
          # For embedded outpost, don't set service_connection
          # For managed outpost, set it
        }
        // optionalAttrs (outpost.serviceConnection != null) {
          service_connection = find "authentik_outposts.dockerserviceconnection" {
            name = outpost.serviceConnection;
          };
        }
        // optionalAttrs (outpost.managed or false) {
          managed = "goauthentik.io/outposts/embedded";
        };
      }
    ) outpostsWithProviders;

  getWarnings =
    { outposts, applications }:
    let
      enabledOutposts = filterAttrs (n: v: v.enable) outposts;
      enabledApps = filterAttrs (n: v: v.enable) applications;

      outpostApps = mapAttrs (
        outpostName: outpost:
        let
          explicitApps = outpost.applications;
          referencingApps = attrNames (filterAttrs (appName: app: app.outpost == outpostName) enabledApps);
        in
        unique (explicitApps ++ referencingApps)
      ) enabledOutposts;

      emptyOutposts = attrNames (
        filterAttrs (
          outpostName: outpost:
          let
            appNames = outpostApps.${outpostName} or [ ];
            validAppNames = filter (appName: hasAttr appName enabledApps) appNames;
          in
          length validAppNames == 0
        ) enabledOutposts
      );

    in
    map (name: "Outpost '${name}' has no applications assigned, skipping") emptyOutposts;
}
