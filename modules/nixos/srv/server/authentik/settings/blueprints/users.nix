{
  lib,
  pkgs,
  authentikLib,
}:

with lib;

let
  inherit (authentikLib) find;

in
{
  generateUserEntries =
    { users }:
    let
      enabledUsers = filterAttrs (n: v: v.enable) users;
    in
    mapAttrsToList (
      name: user:
      let
        groupRefs = map (groupName: find "authentik_core.group" { name = groupName; }) (
          user.groups ++ (if user.isSuperuser then [ "admins" ] else [ ])
        );

      in
      {
        model = "authentik_core.user";
        id = "user-${user.username}";
        state = user.state;
        identifiers.username = user.username;
        attrs =
          (
            {
              username = user.username;
              name = user.name;
              is_active = user.isActive;
              type = user.type;
              path = user.path;
              groups = groupRefs;
              attributes = user.attributes // {
                needs_password_setup = true;
              };
            }
            // optionalAttrs (user.email != null) { email = user.email; }
          )
          // optionalAttrs user.isSuperuser { is_superuser = true; };
        # No password field - authentik handles it
      }
    ) enabledUsers;

  generateGroupEntries =
    { groups }:
    let
      enabledGroups = filterAttrs (n: v: v.enable) groups;

      sortedGroups = sort (
        a: b:
        let
          aGroup = enabledGroups.${a};
          bGroup = enabledGroups.${b};
        in
        if bGroup.parent == a then
          true
        else if aGroup.parent == b then
          false
        else
          a < b
      ) (attrNames enabledGroups);

    in
    map (
      name:
      let
        group = enabledGroups.${name};
      in
      {
        model = "authentik_core.group";
        id = "group-${group.name}";
        state = "present";
        identifiers.name = group.name;
        attrs = {
          name = group.name;
          is_superuser = group.isSuperuserGroup;
          attributes = group.attributes;
        }
        // optionalAttrs (group.parent != null) {
          parent = find "authentik_core.group" { name = group.parent; };
        };
      }
    ) sortedGroups;
}
