{
  lib,
  pkgs,
  authentikLib,
}:

with lib;

let
  providers = import ../providers { inherit lib authentikLib; };
  policiesGen = import ./policies.nix { inherit lib authentikLib; };
  inherit (authentikLib) keyOf find;

in
{
  generate =
    { name, app }:
    let
      providerGen = providers.getGenerator app.provider.type;

      providerEntries = providerGen.mkEntries {
        inherit app;
        providerConfig = app.provider;
      };

      accessEntries = policiesGen.mkEntries {
        inherit app;
        accessConfig = app.accessControl;
      };

      applicationEntry = {
        model = "authentik_core.application";
        id = "application";
        state = "present";
        identifiers.slug = app.slug;
        attrs = {
          name = app.name;
          slug = app.slug;
          provider = keyOf "provider";
          policy_engine_mode = app.accessControl.policyEngineMode;
          meta_description = app.description;
          meta_launch_url = app.launchUrl;
          open_in_new_tab = app.openInNewTab;
        }
        // optionalAttrs (app.group != "") {
          group = app.group;
        }
        // optionalAttrs (app.icon != "") {
          meta_icon = app.icon;
        };
      };

      policyBindings = policiesGen.mkBindings {
        inherit app;
        accessConfig = app.accessControl;
      };

      # No outpost entries here - outposts are handled in outposts.nix
      # The app.outpost field is just a string reference

      allEntries = providerEntries ++ accessEntries ++ [ applicationEntry ] ++ policyBindings;

      blueprint = {
        version = 1;
        metadata = {
          name = "NixOS - ${app.name}";
          labels = {
            "blueprints.goauthentik.io/instantiate" = "true";
          };
        };
        entries = allEntries;
      };

    in
    authentikLib.yaml.mkBlueprint "app-${app.slug}" blueprint;
}
