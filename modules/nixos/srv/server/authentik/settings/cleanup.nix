{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.srv.server.authentik;

  stateDir = "/var/lib/authentik";
  stateLink = "${stateDir}/state.json";
  prometheusDir = "${stateDir}/prometheus";

  protectedUsers = [ "akadmin" ];
  protectedGroups = [ "authentik Admins" ];

  # Add outposts to state
  currentApps = attrNames (filterAttrs (n: v: v.enable && (v.state or "present") != "absent") cfg.applications);
  currentUsers = map (u: u.username) (attrValues (filterAttrs (n: v: v.enable && (v.state or "created") != "absent") cfg.users));
  currentGroups = map (g: g.name) (attrValues (filterAttrs (n: v: v.enable && (v.state or "present") != "absent") cfg.groups));
  currentOutposts = map (o: o.name) (attrValues (filterAttrs (n: v: v.enable) cfg.outposts));

  currentState = pkgs.writeText "authentik-state.json" (builtins.toJSON {
    apps = currentApps;
    users = currentUsers;
    groups = currentGroups;
    outposts = currentOutposts;
  });

  # Update cleanup script
  cleanupScript = pkgs.writeShellScript "authentik-cleanup" ''
    set -euo pipefail

    CURRENT="${currentState}"
    PREVIOUS="${stateLink}"

    PROTECTED_USERS='${builtins.toJSON protectedUsers}'
    PROTECTED_GROUPS='${builtins.toJSON protectedGroups}'

    mkdir -p "$(dirname "$PREVIOUS")"

    if [ ! -e "$PREVIOUS" ]; then
      echo "No previous state, initializing"
      ln -sf "$CURRENT" "$PREVIOUS"
      exit 0
    fi

    PREV_CONTENT=$(cat "$PREVIOUS")
    CURR_CONTENT=$(cat "$CURRENT")

    if [ "$PREV_CONTENT" = "$CURR_CONTENT" ]; then
      echo "No changes"
      ln -sf "$CURRENT" "$PREVIOUS"
      exit 0
    fi

    echo "Checking for removed resources..."

    REMOVE_APPS=""
    REMOVE_USERS=""
    REMOVE_GROUPS=""
    REMOVE_OUTPOSTS=""

    for app in $(echo "$PREV_CONTENT" | ${pkgs.jq}/bin/jq -r '.apps[]' 2>/dev/null || true); do
      if ! echo "$CURR_CONTENT" | ${pkgs.jq}/bin/jq -e ".apps | index(\"$app\")" > /dev/null 2>&1; then
        echo "  Remove app: $app"
        REMOVE_APPS="$REMOVE_APPS $app"
      fi
    done

    for user in $(echo "$PREV_CONTENT" | ${pkgs.jq}/bin/jq -r '.users[]' 2>/dev/null || true); do
      if echo "$PROTECTED_USERS" | ${pkgs.jq}/bin/jq -e "index(\"$user\")" > /dev/null 2>&1; then
        continue
      fi
      if ! echo "$CURR_CONTENT" | ${pkgs.jq}/bin/jq -e ".users | index(\"$user\")" > /dev/null 2>&1; then
        echo "  Remove user: $user"
        REMOVE_USERS="$REMOVE_USERS $user"
      fi
    done

    for group in $(echo "$PREV_CONTENT" | ${pkgs.jq}/bin/jq -r '.groups[]' 2>/dev/null || true); do
      if echo "$PROTECTED_GROUPS" | ${pkgs.jq}/bin/jq -e "index(\"$group\")" > /dev/null 2>&1; then
        continue
      fi
      if ! echo "$CURR_CONTENT" | ${pkgs.jq}/bin/jq -e ".groups | index(\"$group\")" > /dev/null 2>&1; then
        echo "  Remove group: $group"
        REMOVE_GROUPS="$REMOVE_GROUPS $group"
      fi
    done

    for outpost in $(echo "$PREV_CONTENT" | ${pkgs.jq}/bin/jq -r '.outposts[]' 2>/dev/null || true); do
      if ! echo "$CURR_CONTENT" | ${pkgs.jq}/bin/jq -e ".outposts | index(\"$outpost\")" > /dev/null 2>&1; then
        echo "  Remove outpost: $outpost"
        REMOVE_OUTPOSTS="$REMOVE_OUTPOSTS $outpost"
      fi
    done

    if [ -n "$REMOVE_APPS" ] || [ -n "$REMOVE_USERS" ] || [ -n "$REMOVE_GROUPS" ] || [ -n "$REMOVE_OUTPOSTS" ]; then
      echo "Applying cleanup..."
      
      export REMOVE_APPS REMOVE_USERS REMOVE_GROUPS REMOVE_OUTPOSTS
      
      ${cfg.cleanup.akPath} shell << 'PYTHON'
import os
import sys
from django.db import connection

remove_apps = os.environ.get("REMOVE_APPS", "").split()
remove_users = os.environ.get("REMOVE_USERS", "").split()
remove_groups = os.environ.get("REMOVE_GROUPS", "").split()
remove_outposts = os.environ.get("REMOVE_OUTPOSTS", "").split()

errors = []

# Delete applications
for slug in remove_apps:
    if not slug:
        continue
    try:
        from authentik.core.models import Application
        app = Application.objects.filter(slug=slug).first()
        if app:
            print(f"Deleting application: {slug}")
            provider = app.provider
            app.delete()
            if provider:
                print(f"Deleting provider: {provider.name}")
                provider.delete()
        else:
            print(f"Application not found: {slug}")
    except Exception as e:
        errors.append(f"Failed to delete app {slug}: {e}")

# Delete users
for username in remove_users:
    if not username:
        continue
    try:
        from authentik.core.models import User
        user = User.objects.filter(username=username).first()
        if user:
            print(f"Deleting user: {username}")
            user.delete()
        else:
            print(f"User not found: {username}")
    except Exception as e:
        errors.append(f"Failed to delete user {username}: {e}")

# Delete groups using raw SQL
for name in remove_groups:
    if not name:
        continue
    try:
        with connection.cursor() as cursor:
            cursor.execute("DELETE FROM authentik_core_group WHERE name = %s", [name])
            if cursor.rowcount > 0:
                print(f"Deleted group: {name}")
            else:
                print(f"Group not found: {name}")
    except Exception as e:
        errors.append(f"Failed to delete group {name}: {e}")

# Delete outposts
for name in remove_outposts:
    if not name:
        continue
    try:
        from authentik.outposts.models import Outpost
        outpost = Outpost.objects.filter(name=name).first()
        if outpost:
            print(f"Deleting outpost: {name}")
            outpost.delete()
        else:
            print(f"Outpost not found: {name}")
    except Exception as e:
        errors.append(f"Failed to delete outpost {name}: {e}")

if errors:
    print("Errors occurred:")
    for err in errors:
        print(f"  {err}")

print("Cleanup complete")
PYTHON
      
      echo "Cleanup applied"
    else
      echo "No cleanup needed"
    fi

    ln -sf "$CURRENT" "$PREVIOUS"
    echo "State updated"
  '';

  authentikWorkerService = config.systemd.services.authentik-worker or { };
  authentikWorkerEnv = authentikWorkerService.environment or { };
  authentikWorkerEnvFiles = authentikWorkerService.serviceConfig.EnvironmentFile or [ ];
in
{
  options.srv.server.authentik.cleanup = {
    enable = mkEnableOption "automatic cleanup of removed resources";

    akPath = mkOption {
      type = types.str;
      default = "${pkgs.authentik}/bin/ak";
      description = "Path to ak CLI tool";
    };

    user = mkOption {
      type = types.str;
      default = "authentik";
      description = "User to run cleanup as";
    };

    group = mkOption {
      type = types.str;
      default = "authentik";
      description = "Group to run cleanup as";
    };

    inheritEnvironment = mkOption {
      type = types.bool;
      default = true;
      description = "Inherit environment from authentik-worker service";
    };
  };

  config = mkIf (cfg.enable && cfg.cleanup.enable) {
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 ${cfg.cleanup.user} ${cfg.cleanup.group} -"
      "d ${prometheusDir} 0755 ${cfg.cleanup.user} ${cfg.cleanup.group} -"
    ];

    systemd.services.authentik-blueprints-cleanup = {
      description = "Cleanup removed authentik resources";
      after = [
        "authentik-worker.service"
        "authentik.service"
        "postgresql.service"
      ];
      wants = [ "authentik-worker.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = (mkIf cfg.cleanup.inheritEnvironment authentikWorkerEnv) // {
        # Override prometheus dir to our own writable location
        PROMETHEUS_MULTIPROC_DIR = prometheusDir;
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = cleanupScript;
        RemainAfterExit = true;
        User = cfg.cleanup.user;
        Group = cfg.cleanup.group;
      }
      // optionalAttrs (cfg.cleanup.inheritEnvironment && authentikWorkerEnvFiles != [ ]) {
        EnvironmentFile = authentikWorkerEnvFiles;
      };

      restartTriggers = [ currentState ];
    };
  };
}
