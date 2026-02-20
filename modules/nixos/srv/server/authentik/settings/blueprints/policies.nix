{ lib, authentikLib }:

with lib;

let
  inherit (authentikLib) keyOf;

in
{
  mkEntries =
    { app, accessConfig }:
    let
      groupName = if accessConfig.groupName != null then accessConfig.groupName else "${app.slug}";

      groupEntry = optional accessConfig.createGroup {
        model = "authentik_core.group";
        id = "access-group";
        state = "present";
        identifiers.name = groupName;
        attrs = {
          name = groupName;
          is_superuser = false;
        };
      };

      groupPolicy = optional accessConfig.createGroup {
        model = "authentik_policies_expression.expressionpolicy";
        id = "group-policy";
        state = "present";
        identifiers.name = "${app.name} Group Policy";
        attrs = {
          name = "${app.name} Group Policy";
          expression = ''
            from authentik.core.models import Group
            group = Group.objects.filter(name="${groupName}").first()
            if not group:
                return False
            return request.user.ak_groups.filter(pk=group.pk).exists()
          '';
        };
      };

      allowedGroupsPolicy = optional (accessConfig.allowedGroups != [ ]) {
        model = "authentik_policies_expression.expressionpolicy";
        id = "allowed-groups-policy";
        state = "present";
        identifiers.name = "${app.name} Allowed Groups Policy";
        attrs = {
          name = "${app.name} Allowed Groups Policy";
          expression = ''
            allowed = ${builtins.toJSON accessConfig.allowedGroups
            ++ (if accessConfig.createGroup then [accessConfig.groupName] else [])}
            user_groups = [g.name for g in request.user.ak_groups.all()]
            return any(g in user_groups for g in allowed)
          '';
        };
      };

      customPolicyEntry = optional (accessConfig.customPolicy != null) {
        model = "authentik_policies_expression.expressionpolicy";
        id = "custom-policy";
        state = "present";
        identifiers.name = "${app.name} Custom Policy";
        attrs = {
          name = "${app.name} Custom Policy";
          expression = accessConfig.customPolicy;
        };
      };

    in
    groupEntry ++ groupPolicy ++ allowedGroupsPolicy ++ customPolicyEntry;

  mkBindings =
    { app, accessConfig }:
    let
      groupBinding = optional accessConfig.createGroup {
        model = "authentik_policies.policybinding";
        id = "group-policy-binding";
        state = "present";
        identifiers = {
          order = 0;
          target = keyOf "application";
          policy = keyOf "group-policy";
        };
        attrs = {
          enabled = true;
          order = 0;
          timeout = 30;
        };
      };

      allowedGroupsBinding = optional (accessConfig.allowedGroups != [ ]) {
        model = "authentik_policies.policybinding";
        id = "allowed-groups-binding";
        state = "present";
        identifiers = {
          order = 1;
          target = keyOf "application";
          policy = keyOf "allowed-groups-policy";
        };
        attrs = {
          enabled = true;
          order = 1;
          timeout = 30;
        };
      };

      customBinding = optional (accessConfig.customPolicy != null) {
        model = "authentik_policies.policybinding";
        id = "custom-policy-binding";
        state = "present";
        identifiers = {
          order = 2;
          target = keyOf "application";
          policy = keyOf "custom-policy";
        };
        attrs = {
          enabled = true;
          order = 2;
          timeout = 30;
        };
      };

    in
    groupBinding ++ allowedGroupsBinding ++ customBinding;
}
