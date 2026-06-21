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

  # Samba schema for OpenLDAP (LDIF format for cn=confiopenldap)
  sambaSchemaLdif = import ./samba-ldif.nix { inherit pkgs; };
  rfc2307bisSchemaLdif = import ./rfc2307bis-ldif.nix { inherit pkgs; };
  sambaDomainName = "HOMESERVER";
  sambaSID = "S-1-5-21-3226911021-3024596977-3362438729";

  upsertUser = import ./upsert-user.nix { inherit pkgs basedn sambaSID; };

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
          default = [ "netusers" ];
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
          type = listOf (enum [
            "posix"
            "uniqueNames"
            "names"
          ]);
          default = [ "names" ];
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
      services = assignIds (
        [
          {
            name = "authelia";
            groups = [
              "ldap_readers"
              "ldap_writers"
              "ldap_managers"
              "samba_writers"
            ];
            password = cfg.ldap.secret.authelia-password;
          }
        ]
        ++ cfg.ldap.openldap.services
      ) 18000 "uid";

      users = (assignIds (cfg.ldap.openldap.users) 15000 "uid");

      groups =
        (assignIds (
          [
            {
              name = "ldap_readers";
              type = [ "names" ];
            }
            {
              name = "ldap_writers";
              type = [ "names" ];
            }
            {
              name = "ldap_managers";
              type = [ "names" ];
            }

            {
              name = "samba_writers";
              type = [ "names" ];
            }

            {
              name = "netusers";
              type = [
                "names"
                "posix"
              ];
              gid = 10000;
            }

            {
              name = "netadmins";
              type = [
                "names"
                "posix"
              ];
              gid = 10005;
            }
          ]
          ++ cfg.ldap.openldap.groups
        ) 2000 "gid")
        ++ (builtins.map (u: {
          name = u.name;
          gid = u.uid;
          type = [
            "names"
            "posix"
          ];
        }) (users ++ services));

      dcHead = builtins.head (lib.splitString "." cfg.url.domain);
    in
    lib.mkIf (cfg.ldap.enable && cfg.ldap.backend == "openldap") {
      environment.systemPackages = with pkgs; [
        samba # Samba tools
        cyrus_sasl # SASL libraries
        nss_ldap # NSS LDAP module
        pam_ldap # PAM LDAP module
      ];
      age.secrets = lib.mkMerge [
        # Service passwords
        (builtins.listToAttrs (
          builtins.map (s: {
            name = "openldap-service-${s.name}-password";
            value = {
              rekeyFile =
                if (builtins.isPath s.password) then s.password else (cfg.secret.directory + ("/" + s.password));
              owner = "openldap";
              group = "openldap";
            };
          }) services
        ))

        {
          openldap-secrets = {
            rekeyFile = cfg.ldap.openldap.secretsFile;
            owner = "openldap";
            group = "openldap";
          };
        }
      ];

      services.openldap =
        let
          openldapPackage = import ./openldap-smbk5pwd.nix { inherit pkgs; };
        in
        {
          enable = true;

          package = openldapPackage;

          urlList = [
            "ldap://0.0.0.0:${toString cfg.ldap.ports.ldap}/"
            "ldaps://0.0.0.0:${toString cfg.ldap.ports.ldaps}/"
            "ldapi:///"
          ];

          settings = {
            # 1. Enable POSIX and Standard Schemas
            attrs = {
              olcLogLevel = "stats";
            };

            children = {
              "cn=module{0}" = {
                attrs = {
                  objectClass = [ "olcModuleList" ];
                  cn = "module{0}";
                  olcModulePath = [
                    "${openldapPackage}/lib/modules"
                  ];
                  olcModuleLoad = [
                    "smbk5pwd"
                  ];
                };
              };

              "cn=schema" = {
                attrs = {
                  cn = "schema";
                  objectClass = "olcSchemaConfig";
                };
                # Include standard schemas
                includes = [
                  "${pkgs.openldap}/etc/schema/core.ldif"
                  "${pkgs.openldap}/etc/schema/cosine.ldif"
                  "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                  #"${pkgs.openldap}/etc/schema/nis.ldif"
                  rfc2307bisSchemaLdif
                  sambaSchemaLdif
                ];
              };

              # ── Frontend config ──
              "olcDatabase={-1}frontend" = {
                attrs = {
                  objectClass = "olcDatabaseConfig";
                  olcDatabase = "{-1}frontend";
                  olcAccess = [
                    ''
                      {0}to *
                                      by dn.exact="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                                      by * break''

                    "{1}to dn.base=\"\" by * read"
                    "{2}to dn.base=\"cn=Subschema\" by * read"
                  ];
                };
              };

              # ── Config database (cn=config) ──
              "olcDatabase={0}config" = {
                attrs = {
                  objectClass = "olcDatabaseConfig";
                  olcDatabase = "{0}config";
                  olcAccess = [
                    ''
                      {0}to *
                                      by dn.exact="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                                      by * none''
                  ];
                };
              };

              "olcDatabase={1}mdb" = {
                attrs = {
                  # REQUIRED: Define the object classes for the database type
                  objectClass = [
                    "olcDatabaseConfig"
                    "olcMdbConfig"
                  ];
                  olcDatabase = "{1}mdb";

                  olcDbDirectory = "/var/lib/openldap/data";
                  olcSuffix = basedn;
                  olcRootDN = "cn=admin,${basedn}";
                  olcRootPW = "{SSHA}gQ3YWHKmqglR/6t5eA/tpGcJOy+nINoA";

                  olcDbIndex = [
                    "objectClass eq"
                    "uid eq"
                    "cn eq,sub"
                    "sambaSID eq"
                  ];

                  # 1GB
                  olcDbMaxSize = "1073741824";

                  olcAccess = [
                    # 1. Root/Localhost can manage everything (via ldapi)
                    "{0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break"
                    # Admins have full access
                    "{3}to * by group.exact=\"cn=netadmins,ou=groups,${basedn}\" manage by * break"

                    "{4}to attrs=userPassword,shadowLastChange,pwdReset,pwdAccountLockedTime,pwdPolicySubentry
                  by group.exact=\"cn=ldap_managers,ou=groups,${basedn}\" manage 
                  by self write
                  by anonymous auth 
                  by * none"

                    "{5}to attrs=userPassword,sambaNTPassword,sambaLMPassword,sambaPwdLastSet
                  by group.exact=\"cn=samba_writers,ou=groups,${basedn}\" write
                  by self write
                  by * none"

                    "{6}to attrs=userPassword,pwdReset,pwdAccountLockedTime,pwdPolicySubentry,shadowLastChange 
                  by group.exact=\"cn=ldap_writers,ou=groups,${basedn}\" write 
                  by anonymous auth 
                  by group.exact=\"cn=ldap_readers,ou=groups,${basedn}\" read 
                  by anonymous auth 
                  by * none"

                    # 3. Standard Read Access for everything else
                    "{7}to * by self read by dn.base=\"${basedn}\" write by * read"
                  ];
                };

                children = {
                  "olcOverlay={0}smbk5pwd".attrs = {
                    objectClass = [
                      "olcOverlayConfig"
                      "olcSmbK5PwdConfig"
                    ];
                    olcOverlay = "{0}smbk5pwd";

                    # NixOS will automatically convert this list into multiple
                    # olcSmbK5PwdEnable lines in the resulting LDIF
                    olcSmbK5PwdEnable = [
                      #"krb5"
                      "samba"
                    ];
                  };
                };
              };
            };
          };

          declarativeContents = {
            "${basedn}" = ''
              dn: ${basedn}
              objectClass: top
              objectClass: dcObject
              objectClass: organization
              dc: ${dcHead}
              o: ${dcHead}

              ${
                lib.concatMapStrings
                  (ou: ''
                    dn: ou=${ou},${basedn}
                    objectClass: organizationalUnit
                    ou: ${ou}

                  '')
                  [
                    "people"
                    "services"
                    "groups"
                    "policies"
                    "idmap"
                  ]
              }dn: cn=default,ou=policies,${basedn}
              objectClass: pwdPolicy
              objectClass: person
              objectClass: top
              cn: default
              sn: default
              pwdAttribute: userPassword
              pwdMaxAge: 0
              pwdSafeModify: FALSE
              pwdMustChange: FALSE
              pwdAllowUserChange: TRUE

              dn: sambaDomainName=${sambaDomainName},${basedn}
              objectClass: sambaDomain
              sambaDomainName: ${sambaDomainName}
              sambaSID: ${sambaSID}
              sambaNextRid: 1000
              ${lib.concatMapStrings (
                g:
                let
                  membersServices = lib.filter (u: lib.elem g.name u.groups) (services);
                  membersUsers = lib.filter (u: lib.elem g.name u.groups) (users);

                  memberNames =
                    (map (s: "cn=${s.name},ou=services,${basedn}") membersServices)
                    ++ (map (u: "uid=${u.name},ou=people,${basedn}") membersUsers);

                  manageMembers = lib.concatMapStrings (
                    t:
                    let
                      member = "${
                        {
                          "posix" = "memberUid";
                          "names" = "member";
                          "uniqueNames" = "member";
                        }
                        ."${t}"
                      }";
                    in
                    (
                      "\n${member}: cn=${g.name},ou=groups,${basedn}${
                        lib.concatMapStrings (m: "\n${member}: ${m}") memberNames
                      }"
                    )
                  ) g.type;

                  class = lib.concatMapStrings (
                    t:
                    "\nobjectClass: ${
                      {
                        "posix" = "posixGroup";
                        "names" = "groupOfNames";
                        "uniqueNames" = "groupOfUniqueNames";
                      }
                      ."${t}"
                    }"
                  ) g.type;
                in
                ''

                  dn: cn=${g.name},ou=groups,${basedn}${class}
                  cn: ${g.name}${
                    if builtins.elem "posix" g.type then "\ngidNumber: ${toString g.gid}" else ""
                  }${manageMembers}
                ''
              ) groups}'';
          };
        };

      systemd.tmpfiles.rules = [
        "d /var/lib/openldap 0750 openldap openldap"
        "d /var/lib/openldap/data 0750 openldap openldap"
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

          # ---------------------------------------------------------
          # PART B: Human Users (Create If Missing, Then Ignore)
          # ---------------------------------------------------------

          ${lib.concatMapStrings (
            user:
            (upsertUser user)
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
            # Delete the user to ensure proper config
            ${pkgs.openldap}/bin/ldapdelete -Y EXTERNAL -H ldapi:/// "cn=${s.name},ou=services,${basedn}" || EXIT_CODE=$?

            # Create the User
            PASS="$(cat ${config.age.secrets."openldap-service-${s.name}-password".path})"

            HASH="$(${pkgs.openldap}/bin/slappasswd -s "$PASS")"

            apply_ldif "dn: cn=${s.name},ou=services,${basedn}
            objectClass: top
            objectClass: simpleSecurityObject
            objectClass: posixAccount
            objectClass: organizationalRole
            cn: ${s.name}
            uid: ${s.name}
            homeDirectory: /var/empty
            loginShell: /bin/false
            uidNumber: ${toString s.uid}
            gidNumber: ${toString s.uid}
            userPassword: $HASH"


            # Enforce the password from Agenix
            ${pkgs.openldap}/bin/ldappasswd -Y EXTERNAL -H ldapi:/// -s "$PASS" "cn=${s.name},ou=services,${basedn}"
          '') services}
        '';
      };
    };
}
