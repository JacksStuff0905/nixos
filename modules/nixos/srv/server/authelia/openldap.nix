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

  types = with lib; {
    ldap-user = lib.types.submodule {
      options = with lib.types; {
        name = mkOption {
          type = str;
        };

        uid = mkOption {
          type = nullOr int;
          default = null;
        };

        email = mkOption {
          type = str;
        };

        password = mkOption {
          type = nullOr str;
          default = null;
        };

        groups = mkOption {
          type = listOf str;
          default = [ ];
        };
      };
    };

    ldap-group = lib.types.submodule {
      options = with lib.types; {
        name = mkOption {
          type = str;
        };

        gid = mkOption {
          type = nullOr int;
          default = null;
        };

        type = mkOption {
          type = enum [
            "posix"
            "uniqueNames"
            "names"
          ];
          default = "names";
        };
      };
    };

    ldap-service = lib.types.submodule {
      options = with lib.types; {
        name = mkOption {
          type = str;
        };

        password = mkOption {
          type = either str path;
        };

        groups = mkOption {
          type = listOf str;
          default = [ ];
        };
      };
    };
  };

  assignIds =
    list: startId: idKey:
    lib.imap0 (
      i: item:
      # If item has explicit ID, use it. Else use startId + i
      item
      // {
        ${idKey} = if (item ? ${idKey} && item."${idKey}" != null) then item.${idKey} else (startId + i);
      }
    ) list;
in
{
  options.srv.server.authelia.ldap.openldap = {
    users = lib.mkOption {
      type = lib.types.listOf types.ldap-user;
    };

    groups = lib.mkOption {
      type = lib.types.listOf types.ldap-group;
      default = [ ];
    };

    services = lib.mkOption {
      type = lib.types.listOf types.ldap-service;
      default = [ ];
    };

    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config =
    let
      services = [
        {
          name = "authelia";
          groups = [
            "ldap_readers"
            "ldap_writers"
            "ldap_managers"
          ];
          password = cfg.ldap.secret.authelia-password;
        }
      ]
      ++ cfg.ldap.openldap.services;

      users = assignIds (cfg.ldap.openldap.users) 1000 "uid";

      groups = assignIds (
        [
          {
            name = "ldap_readers";
            type = "names";
          }
          {
            name = "ldap_writers";
            type = "names";
          }
          {
            name = "ldap_managers";
            type = "names";
          }
        ]
        ++ cfg.ldap.openldap.groups
      ) 2000 "gid";

      dcHead = builtins.head (lib.splitString "." cfg.url.domain);
    in
    lib.mkIf (cfg.ldap.enable && cfg.ldap.backend == "openldap") {
      age.secrets = lib.mkMerge [
        # Service passwords
        (builtins.listToAttrs (
          builtins.map (s: {
            name = "openldap-service-${s.name}-password";
            value = {
              file =
                if (lib.isStorePath s.password) then s.password else cfg.secret.directory + ("/" + s.password);
              owner = "openldap";
              group = "openldap";
            };
          }) services
        ))

        {
          openldap-secrets = {
            file = cfg.ldap.openldap.secretsFile;
            owner = "openldap";
            group = "openldap";
          };
        }
      ];

      services.openldap = {
        enable = true;
        urlList = [
          "ldap://0.0.0.0:3890/"
          "ldaps:///"
          "ldapi:///"
        ];

        settings = {
          # 1. Enable POSIX and Standard Schemas
          attrs = {
            olcLogLevel = "stats";
          };

          children = {

            "cn=schema".includes = [
              "${pkgs.openldap}/etc/schema/core.ldif"
              "${pkgs.openldap}/etc/schema/cosine.ldif"
              "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
              "${pkgs.openldap}/etc/schema/nis.ldif" # <--- POSIX Support
            ];

            "olcDatabase={1}mdb" = {
              attrs = {
                # REQUIRED: Define the object classes for the database type
                objectClass = [
                  "olcDatabaseConfig"
                  "olcMdbConfig"
                ];

                olcDbDirectory = "/var/lib/openldap/data";
                olcSuffix = basedn;
                olcRootDN = "cn=admin,${basedn}";
                olcRootPW = "{SSHA}gQ3YWHKmqglR/6t5eA/tpGcJOy+nINoA";

                # 1GB
                olcDbMaxSize = "1073741824";

                olcAccess = [
                  # 1. Root/Localhost can manage everything (via ldapi)
                  "{0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break"

                  "{1}to attrs=userPassword,shadowLastChange,pwdReset,pwdAccountLockedTime,pwdPolicySubentry
                  by group.exact=\"cn=ldap_managers,ou=groups,${basedn}\" manage 
                  by self write
                  by anonymous auth 
                  by * none"

                  "{2}to attrs=userPassword,pwdReset,pwdAccountLockedTime,pwdPolicySubentry,shadowLastChange 
                  by group.exact=\"cn=ldap_writers,ou=groups,${basedn}\" write 
                  by anonymous auth 
                  by group.exact=\"cn=ldap_readers,ou=groups,${basedn}\" read 
                  by anonymous auth 
                  by * none"

                  # 3. Standard Read Access for everything else
                  "{3}to * by self read by dn.base=\"${basedn}\" write by * read"
                ];
              };
            };
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/openldap 0750 0 0"
        "d /var/lib/openldap/data 0750 0 0"
      ];

      systemd.services.openldap = {
        serviceConfig = {
          User = lib.mkForce "openldap";
          Group = lib.mkForce "openldap";
        };

      };

      systemd.services.ldap-provisioning = {
        description = "Provision LDAP Users and Structure";
        after = [ "openldap.service" ];
        wants = [ "openldap.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root"; # Critical: Runs as root to read Agenix secrets + match ACL
          EnvironmentFile = config.age.secrets.openldap-secrets.path;
        };

        script = ''
          set -euo pipefail

          URI="ldapi://%2Frun%2Fopenldap%2Fldapi"
          LDIF_FILE="/tmp/ldap_provision.ldif"

          # Wait for the socket to be ready
          until [ -S /run/openldap/ldapi ]; do
            echo "Waiting for LDAP socket..."
            sleep 1
          done

          apply_ldif() {
            # 1. Capture the piped content (Heredoc) into a variable first
            #sed 's/^[ \t]*//' > "$LDIF_FILE"
            echo "$1" | sed 's/^[ \t]*//' > "$LDIF_FILE"

            
            set +eu 
            # 2. Echo it into ldapadd
            if [ "$2" == "modify" ]; then
              OUTPUT=$(${pkgs.openldap}/bin/ldapmodify -Y EXTERNAL -H "$URI" -f "$LDIF_FILE")
            else 
              OUTPUT=$(${pkgs.openldap}/bin/ldapadd -Y EXTERNAL -H "$URI" -f "$LDIF_FILE")
            fi

            EXIT_CODE=$?
            set -eu

            # 3. Check results
            if [ $EXIT_CODE -eq 0 ]; then
              echo "SUCCESS: Entry added."
            elif [ $EXIT_CODE -eq 68 ]; then
              echo "SKIPPED: Entry already exists."
            else
              echo "!!! FAIL !!!"
              echo "Error Code: $EXIT_CODE"
              echo "LDAP Output: $OUTPUT"
              echo "LDIF Content was:"
              cat $LDIF_FILE
              exit 1
            fi
          }

          echo "--- Provisioning Root Domain ---"
          apply_ldif "dn: ${basedn}
          objectClass: top
          objectClass: dcObject
          objectClass: organization
          o: ${dcHead}
          dc: ${dcHead}"

          # 2. Structure (OUs)
          echo "--- Provisioning Organizational Units ---"
          for OU in people services groups policies; do
            apply_ldif "
            dn: ou=$OU,${basedn}
            objectClass: organizationalUnit
            ou: $OU"
          done

          echo "Provisioning Default Password Policy..."
          apply_ldif "dn: cn=default,ou=policies,${basedn}
          objectClass: pwdPolicy
          objectClass: person
          objectClass: top
          cn: default
          sn: default
          pwdAttribute: userPassword
          pwdMaxAge: 0
          pwdSafeModify: FALSE
          pwdMustChange: FALSE
          pwdAllowUserChange: TRUE"

          # ---------------------------------------------------------
          # PART B: Human Users (Create If Missing, Then Ignore)
          # ---------------------------------------------------------

          ${lib.concatMapStrings (
            user:
            ''
              HASH=$(${pkgs.openldap}/bin/slappasswd -s "${if user.password == null then user.name else user.password}")

              apply_ldif "
              dn: uid=${user.name},ou=people,${basedn}
              objectClass: inetOrgPerson
              objectClass: posixAccount
              objectClass: shadowAccount
              uid: ${user.name}
              cn: ${user.name}
              sn: ${user.name}
              uidNumber: ${toString user.uid}
              gidNumber: 1000
              homeDirectory: /home/${user.name}
              loginShell: /bin/bash
              userPassword: $HASH
              mail: ${user.email}
              pwdReset: TRUE"
            ''
            + (
              if user.email != null then
                ''

                  apply_ldif "
                  dn: uid=${user.name},ou=people,${basedn}
                  changetype: modify
                  replace: mail
                  mail: ${user.email}
                  " "modify"
                ''
              else
                ""
            )
            + (
              if user.password != null then
                ''

                  # Force password (it was declared through nix)
                  ${pkgs.openldap}/bin/ldappasswd -Y EXTERNAL -H ldapi:/// -s "${user.password}" "uid=${user.name},ou=people,${basedn}"
                ''
              else
                ""
            )
          ) users}

          # ---------------------------------------------------------
          # PART C: Service Users (Create + Enforce Agenix Password)
          # ---------------------------------------------------------
          ${lib.concatMapStrings (s: ''
            # A. Create the User (Idempotent)
            PASS="$(cat ${config.age.secrets."openldap-service-${s.name}-password".path})"

            HASH="$(${pkgs.openldap}/bin/slappasswd -s "$PASS")"

            apply_ldif "dn: cn=${s.name},ou=services,${basedn}
            objectClass: simpleSecurityObject
            objectClass: organizationalRole
            cn: ${s.name}
            userPassword: $HASH"


            # 2. ALWAYS enforce the password from Agenix
            # ldappasswd updates the password safely (hashing it)
            ${pkgs.openldap}/bin/ldappasswd -Y EXTERNAL -H ldapi:/// -s "$PASS" "cn=${s.name},ou=services,${basedn}"
          '') services}

          # Groups
          echo "Provisioning Custom Groups..."
          ${lib.concatMapStrings (
            g:
            let
              membersServices = lib.filter (u: lib.elem g.name u.groups) (services);
              membersUsers = lib.filter (u: lib.elem g.name u.groups) (users);

              memberNames =
                (map (s: "cn=${s.name},ou=services,${basedn}") membersServices)
                ++ (map (u: "uid=${u.name},ou=people,${basedn}") membersUsers);

              member =
                {
                  "posix" = "memberUid";
                  "names" = "member";
                  "uniqueNames" = "member";
                }
                ."${g.type}";

              class =
                {
                  "posix" = "posixGroup";
                  "names" = "groupOfNames";
                  "uniqueNames" = "groupOfUniqueNames";
                }
                ."${g.type}";

            in
            ''
              echo "Processing group: ${g.name} (GID: ${toString g.gid})"

              # A. Create the Group (if missing)
              apply_ldif "
                dn: cn=${g.name},ou=groups,${basedn}
                objectClass: ${class}
                cn: ${g.name}${if g.type == "posix" then "\ngidNumber: ${toString g.gid}" else ""}
                member: cn=${g.name},ou=groups,${basedn}
              "

              # Check if we have members to add
              ${
                if memberNames != [ ] then
                  ''
                    echo "  -> Setting members: ${lib.concatStringsSep ", " memberNames}"

                    # Write modify LDIF
                    apply_ldif "
                    dn: cn=${g.name},ou=groups,${basedn}
                    changetype: modify
                    replace: ${member}
                    ${lib.concatMapStrings (m: "${member}: ${m}\n") memberNames}
                    " "modify"
                  ''
                else
                  ''
                    # No members found in Nix for this group -> Clear LDAP members
                    echo "  -> Clearing all members"

                    apply_ldif "
                    dn: cn=${g.name},ou=groups,${basedn}
                    changetype: modify
                    delete: ${member}
                    " "modify"
                  ''
              }
            ''
          ) groups}

        '';
      };
    };
}
