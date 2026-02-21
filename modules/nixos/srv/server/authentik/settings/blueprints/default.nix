{
  lib,
  pkgs,
  authentikLib,
  applications,
  blueprints,
  users ? { },
  groups ? { },
  outposts ? { },
}:

with lib;

let
  appGen = import ./application.nix { inherit lib pkgs authentikLib; };
  usersGen = import ./users.nix { inherit lib pkgs authentikLib; };
  outpostsGen = import ./outposts.nix { inherit lib pkgs authentikLib; };
  providers = import ../providers { inherit lib authentikLib; };

  defaultGroups = {
    admins = {
      enable = true;
      name = "admins";
      isSuperuserGroup = true;
      parent = null;
      attributes = { };
      state = "present";
    };
  };

  allGroups = defaultGroups // groups;

  enabledApps = filterAttrs (n: v: v.enable && (v.state or "present") != "absent") applications;
  enabledBlueprints = filterAttrs (n: v: if v ? enable then v.enable else true) blueprints;
  enabledUsers = filterAttrs (n: v: v.enable && (v.state or "created") != "absent") users;
  enabledGroups = (filterAttrs (n: v: v.enable && (v.state or "present") != "absent") allGroups);
  enabledOutposts = filterAttrs (n: v: v.enable) outposts;

  appFiles = mapAttrs (name: app: appGen.generate { inherit name app; }) enabledApps;

  customFiles = mapAttrs (
    name: bp:
    if bp.file != null then
      bp.file
    else if bp.content != null then
      pkgs.writeText "${name}.yaml" bp.content
    else
      authentikLib.yaml.mkBlueprint name {
        version = 1;
        metadata = {
          name = bp.name;
          labels = {
            "blueprints.goauthentik.io/instantiate" = "true";
          };
        }
        // bp.metadata;
        context = bp.context;
        entries = bp.entries;
      }
  ) enabledBlueprints;

  usersAndGroupsBlueprint =
    if enabledUsers != { } || enabledGroups != { } then
      {
        "00-users-groups" = authentikLib.yaml.mkBlueprint "users-groups" {
          version = 1;
          metadata = {
            name = "NixOS - Users and Groups";
            labels = {
              "blueprints.goauthentik.io/instantiate" = "true";
            };
          };
          entries =
            (usersGen.generateGroupEntries { groups = enabledGroups; })
            ++ (usersGen.generateUserEntries { users = enabledUsers; });
        };
      }
    else
      { };

  outpostEntries = outpostsGen.generateOutpostEntries {
    outposts = enabledOutposts;
    applications = enabledApps;
  };

  outpostsBlueprint =
    if outpostEntries != [ ] then
      {
        "99-outposts" = authentikLib.yaml.mkBlueprint "outposts" {
          version = 1;
          metadata = {
            name = "NixOS - Outposts";
            labels = {
              "blueprints.goauthentik.io/instantiate" = "true";
            };
          };
          entries = outpostEntries;
        };
      }
    else
      { };

  allFiles = usersAndGroupsBlueprint // appFiles // customFiles // outpostsBlueprint;

  # Validation errors
  validationErrors = flatten (
    (mapAttrsToList (
      name: app:
      let
        gen = providers.getGenerator app.provider.type;
      in
      gen.validate {
        inherit app;
        providerConfig = app.provider;
      }
    ) enabledApps)
    ++ (mapAttrsToList (
      name: app:
      optional (
        app.outpost != null && !hasAttr app.outpost outposts
      ) "Application '${name}' references non-existent outpost '${app.outpost}'"
    ) enabledApps)
    ++ (mapAttrsToList (
      name: app:
      let
        outpost = outposts.${app.outpost} or null;
        providerType = app.provider.type;
        outpostType = if outpost != null then outpost.type else null;
        compatible = {
          proxy = [ "proxy" ];
          ldap = [ "ldap" ];
          oauth2 = [ ];
          saml = [ ];
        };
      in
      optional
        (app.outpost != null && outpost != null && !elem providerType (compatible.${outpostType} or [ ]))
        "Application '${name}' has provider type '${providerType}' but outpost '${app.outpost}' is type '${outpostType}'"
    ) enabledApps)
    ++ (outpostsGen.getWarnings {
      outposts = enabledOutposts;
      applications = enabledApps;
    })
  );

in
{
  blueprintsDir = pkgs.runCommand "authentik-blueprints" { } ''
    mkdir -p $out
    ${concatStringsSep "\n" (
      mapAttrsToList (name: file: ''
        cp ${file} $out/${name}.yaml
      '') allFiles
    )}
    chmod 644 $out/*.yaml
  '';

  files = allFiles;
  warnings = validationErrors;
  assertions = [ ];
}
