{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.srv.server.authelia;

  mkUrl = proto: name: "${proto}://${name}.${cfg.url.domain}";

  basedn = builtins.concatStringsSep "," (
    builtins.map (d: "dc=${d}") (lib.splitString "." cfg.url.domain)
  );

  provisionScript = pkgs.writeShellScript "lldap-posix-provision" ''
    set -euo pipefail

    LDAP_URI="ldap://127.0.0.1:${toString cfg.ldap.ports.ldap}"
    BASE_DN="${basedn}"
    BIND_DN="uid=admin,ou=people,$BASE_DN"
    BIND_PW="$(cat ${config.age.secrets.lldap-authelia-password.path})"

    # Hash UUID to ID in range 100000-600000
    uuid_to_id() {
      local hash=$(echo -n "$1" | sha256sum | cut -c1-8)
      echo $((100000 + 16#$hash % 500000))
    }

    # Provision a single entry
    provision() {
      local dn="$1" uuid="$2" attr="$3"
      local id=$(uuid_to_id "$uuid")
      echo "  $dn → $attr=$id"
      
      ldapmodify -x -H "$LDAP_URI" -D "$BIND_DN" -w "$BIND_PW" 2>/dev/null <<EOF
dn: $dn
changetype: modify
add: $attr
$attr: $id
EOF
    }

    # Find entries missing an attribute and provision them
    provision_missing() {
      local base="$1" filter="$2" attr="$3"
      
      ldapsearch -x -LLL -H "$LDAP_URI" -D "$BIND_DN" -w "$BIND_PW" \
        -b "$base" "$filter" dn entryUUID 2>/dev/null | \
      awk '/^dn:/{dn=substr($0,5)} /^entryUUID:/{uuid=$2} /^$/{if(dn&&uuid)print dn"|"uuid;dn=uuid=""}' | \
      while IFS='|' read -r dn uuid; do
        [ -n "$dn" ] && [ -n "$uuid" ] && provision "$dn" "$uuid" "$attr"
      done
    }

    echo "=== Users ==="
    provision_missing "ou=people,$BASE_DN" "(&(objectClass=person)(!(uidNumber=*)))" "uidNumber"

    echo "=== Groups ==="
    provision_missing "ou=groups,$BASE_DN" "(&(objectClass=groupOfUniqueNames)(!(gidNumber=*)))" "gidNumber"

    echo "=== Done ==="
  '';
in
{
  options.srv.server.authelia.ldap.lldap = {
  };

  config = lib.mkIf (cfg.ldap.enable && cfg.ldap.backend == "lldap") {
    age.secrets = {
      lldap-jwt-secret = {
        rekeyFile = cfg.secret.directory + ("/" + cfg.ldap.secret.jwt-secret);
        owner = "authelia-main";
        group = "authelia-main";
      };

      lldap-authelia-password = {
        rekeyFile = cfg.secret.directory + ("/" + cfg.ldap.secret.authelia-password);
        owner = "authelia-main";
        group = "authelia-main";
      };
    };

    systemd.services.lldap.serviceConfig = {
      User = lib.mkForce "authelia-main";
      Group = lib.mkForce "authelia-main";
    };

    services.lldap = {
      enable = true;

      settings = {
        http_host = "0.0.0.0";
        http_port = cfg.ldap.ports.http;

        force_ldap_user_pass_reset = "always";

        ldap_host = "0.0.0.0";
        ldap_port = cfg.ldap.ports.ldap;

        posix_enabled = true;
        posix_id_min = 10000;

        ldap_base_dn = basedn;
        max_connections = 1024;
        max_open_files = 1024;
        #"dc=example,dc=com";

        # Public URL for LLDAP web UI (users access this to change passwords)
        http_url = mkUrl cfg.ldap.url.proto cfg.ldap.url.name;
      };

      environment = {
        LLDAP_JWT_SECRET_FILE = config.age.secrets.lldap-jwt-secret.path;
        LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.lldap-authelia-password.path;
      };
    };

    systemd.services.lldap-posix-provision = {
      description = "Provision POSIX attributes";
      after = [ "lldap.service" ];
      requires = [ "lldap.service" ];
      path = with pkgs; [
        openldap
        coreutils
        gawk
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        ExecStart = provisionScript;
      };
    };

    systemd.timers.lldap-posix-provision = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "15min";
      };
    };
  };
}
