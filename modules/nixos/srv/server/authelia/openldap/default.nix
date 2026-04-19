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

  # Samba schema for OpenLDAP (LDIF format for cn=config)
  sambaSchemaLdif = pkgs.writeText "samba.ldif" ''
    dn: cn=samba,cn=schema,cn=config
    objectClass: olcSchemaConfig
    cn: samba
    olcAttributeTypes: {0}( 1.3.6.1.4.1.7165.2.1.24 NAME 'sambaLMPassword' DESC 'LanManager Password' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{32} SINGLE-VALUE )
    olcAttributeTypes: {1}( 1.3.6.1.4.1.7165.2.1.25 NAME 'sambaNTPassword' DESC 'MD4 hash of the unicode password' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{32} SINGLE-VALUE )
    olcAttributeTypes: {2}( 1.3.6.1.4.1.7165.2.1.26 NAME 'sambaAcctFlags' DESC 'Account Flags' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{16} SINGLE-VALUE )
    olcAttributeTypes: {3}( 1.3.6.1.4.1.7165.2.1.27 NAME 'sambaPwdLastSet' DESC 'Timestamp of the last password update' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {4}( 1.3.6.1.4.1.7165.2.1.28 NAME 'sambaPwdCanChange' DESC 'Timestamp of when the user is allowed to update the password' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {5}( 1.3.6.1.4.1.7165.2.1.29 NAME 'sambaPwdMustChange' DESC 'Timestamp of when the password will expire' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {6}( 1.3.6.1.4.1.7165.2.1.30 NAME 'sambaLogonTime' DESC 'Timestamp of last logon' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {7}( 1.3.6.1.4.1.7165.2.1.31 NAME 'sambaLogoffTime' DESC 'Timestamp of last logoff' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {8}( 1.3.6.1.4.1.7165.2.1.32 NAME 'sambaKickoffTime' DESC 'Timestamp of when the user will be logged off automatically' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {9}( 1.3.6.1.4.1.7165.2.1.48 NAME 'sambaBadPasswordCount' DESC 'Bad password attempt count' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {10}( 1.3.6.1.4.1.7165.2.1.49 NAME 'sambaBadPasswordTime' DESC 'Time of the last bad password attempt' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {11}( 1.3.6.1.4.1.7165.2.1.33 NAME 'sambaHomeDrive' DESC 'Driver letter of home directory mapping' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{4} SINGLE-VALUE )
    olcAttributeTypes: {12}( 1.3.6.1.4.1.7165.2.1.34 NAME 'sambaLogonScript' DESC 'Logon script path' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{255} SINGLE-VALUE )
    olcAttributeTypes: {13}( 1.3.6.1.4.1.7165.2.1.35 NAME 'sambaProfilePath' DESC 'Roaming profile path' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{255} SINGLE-VALUE )
    olcAttributeTypes: {14}( 1.3.6.1.4.1.7165.2.1.36 NAME 'sambaUserWorkstations' DESC 'List of user workstations the user is allowed to logon to' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{255} SINGLE-VALUE )
    olcAttributeTypes: {15}( 1.3.6.1.4.1.7165.2.1.37 NAME 'sambaHomePath' DESC 'Home directory UNC path' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{128} )
    olcAttributeTypes: {16}( 1.3.6.1.4.1.7165.2.1.38 NAME 'sambaDomainName' DESC 'Windows NT domain to which the user belongs' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{128} )
    olcAttributeTypes: {17}( 1.3.6.1.4.1.7165.2.1.20 NAME 'sambaSID' DESC 'Security ID' EQUALITY caseIgnoreIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{64} SINGLE-VALUE )
    olcAttributeTypes: {18}( 1.3.6.1.4.1.7165.2.1.23 NAME 'sambaPrimaryGroupSID' DESC 'Primary Group Security ID' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{64} SINGLE-VALUE )
    olcAttributeTypes: {19}( 1.3.6.1.4.1.7165.2.1.51 NAME 'sambaGroupType' DESC 'NT Group Type' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {20}( 1.3.6.1.4.1.7165.2.1.52 NAME 'sambaNTGroupMembers' DESC 'NT Group Members' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
    olcAttributeTypes: {21}( 1.3.6.1.4.1.7165.2.1.53 NAME 'sambaMungedDial' DESC 'Base64 encoded user parameter string' EQUALITY caseExactMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{1050} )
    olcAttributeTypes: {22}( 1.3.6.1.4.1.7165.2.1.54 NAME 'sambaPasswordHistory' DESC 'Concatenated MD5 hashes of the salted NT passwords used on this account' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{32} )
    olcAttributeTypes: {23}( 1.3.6.1.4.1.7165.2.1.55 NAME 'sambaLogonHours' DESC 'Logon Hours' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{42} SINGLE-VALUE )
    olcAttributeTypes: {24}( 1.3.6.1.4.1.7165.2.1.56 NAME 'sambaMinPwdLength' DESC 'Minimal password length' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {25}( 1.3.6.1.4.1.7165.2.1.57 NAME 'sambaPwdHistoryLength' DESC 'Length of Password History Entries' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {26}( 1.3.6.1.4.1.7165.2.1.58 NAME 'sambaMinPwdAge' DESC 'Minimum password age in seconds' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {27}( 1.3.6.1.4.1.7165.2.1.59 NAME 'sambaMaxPwdAge' DESC 'Maximum password age in seconds' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {28}( 1.3.6.1.4.1.7165.2.1.60 NAME 'sambaLockoutDuration' DESC 'Lockout duration in minutes' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {29}( 1.3.6.1.4.1.7165.2.1.61 NAME 'sambaLockoutObservationWindow' DESC 'Reset time after lockout in minutes' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {30}( 1.3.6.1.4.1.7165.2.1.62 NAME 'sambaLockoutThreshold' DESC 'Lockout users after bad logon attempts' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {31}( 1.3.6.1.4.1.7165.2.1.63 NAME 'sambaForceLogoff' DESC 'Disconnect Users outside logon hours' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {32}( 1.3.6.1.4.1.7165.2.1.64 NAME 'sambaRefuseMachinePwdChange' DESC 'Allow Machine Password changes' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {33}( 1.3.6.1.4.1.7165.2.1.65 NAME 'sambaTrustFlags' DESC 'Trust Password Flags' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
    olcAttributeTypes: {34}( 1.3.6.1.4.1.7165.2.1.66 NAME 'sambaNextRid' DESC 'Next NT rid to give out for anything' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {35}( 1.3.6.1.4.1.7165.2.1.67 NAME 'sambaNextGroupRid' DESC 'Next NT rid to give out for groups' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {36}( 1.3.6.1.4.1.7165.2.1.68 NAME 'sambaNextUserRid' DESC 'Next NT rid to give out for users' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {37}( 1.3.6.1.4.1.7165.2.1.69 NAME 'sambaAlgorithmicRidBase' DESC 'Base at which the samba RID generation algorithm should operate' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {38}( 1.3.6.1.4.1.7165.2.1.70 NAME 'sambaShareName' DESC 'Share Name' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
    olcAttributeTypes: {39}( 1.3.6.1.4.1.7165.2.1.71 NAME 'sambaOptionName' DESC 'Option Name' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{256} )
    olcAttributeTypes: {40}( 1.3.6.1.4.1.7165.2.1.72 NAME 'sambaBoolOption' DESC 'A boolean option' EQUALITY booleanMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.7 SINGLE-VALUE )
    olcAttributeTypes: {41}( 1.3.6.1.4.1.7165.2.1.73 NAME 'sambaIntegerOption' DESC 'An integer option' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
    olcAttributeTypes: {42}( 1.3.6.1.4.1.7165.2.1.74 NAME 'sambaStringOption' DESC 'A string option' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 SINGLE-VALUE )
    olcAttributeTypes: {43}( 1.3.6.1.4.1.7165.2.1.75 NAME 'sambaStringListOption' DESC 'A string list option' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )
    olcAttributeTypes: {44}( 1.3.6.1.4.1.7165.2.1.76 NAME 'sambaSIDList' DESC 'Security ID List' EQUALITY caseIgnoreIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
    olcObjectClasses: {0}( 1.3.6.1.4.1.7165.2.2.6 NAME 'sambaSamAccount' DESC 'Samba 3.0 Auxilary SAM Account' SUP top AUXILIARY MUST ( uid $ sambaSID ) MAY ( cn $ sambaLMPassword $ sambaNTPassword $ sambaPwdLastSet $ sambaLogonTime $ sambaLogoffTime $ sambaKickoffTime $ sambaPwdCanChange $ sambaPwdMustChange $ sambaAcctFlags $ displayName $ sambaHomePath $ sambaHomeDrive $ sambaLogonScript $ sambaProfilePath $ description $ sambaUserWorkstations $ sambaPrimaryGroupSID $ sambaDomainName $ sambaMungedDial $ sambaBadPasswordCount $ sambaBadPasswordTime $ sambaPasswordHistory $ sambaLogonHours ) )
    olcObjectClasses: {1}( 1.3.6.1.4.1.7165.2.2.4 NAME 'sambaGroupMapping' DESC 'Samba Group Mapping' SUP top AUXILIARY MUST ( gidNumber $ sambaSID $ sambaGroupType ) MAY ( displayName $ description $ sambaSIDList ) )
    olcObjectClasses: {2}( 1.3.6.1.4.1.7165.2.2.5 NAME 'sambaDomain' DESC 'Samba Domain Information' SUP top STRUCTURAL MUST ( sambaDomainName $ sambaSID ) MAY ( sambaNextRid $ sambaNextGroupRid $ sambaNextUserRid $ sambaAlgorithmicRidBase $ sambaMinPwdLength $ sambaPwdHistoryLength $ sambaMinPwdAge $ sambaMaxPwdAge $ sambaLockoutDuration $ sambaLockoutObservationWindow $ sambaLockoutThreshold $ sambaForceLogoff $ sambaRefuseMachinePwdChange ) )
    olcObjectClasses: {3}( 1.3.6.1.4.1.7165.2.2.7 NAME 'sambaUnixIdPool' DESC 'Pool for allocating UNIX uids/gids' SUP top AUXILIARY MUST ( uidNumber $ gidNumber ) )
    olcObjectClasses: {4}( 1.3.6.1.4.1.7165.2.2.8 NAME 'sambaIdmapEntry' DESC 'Mapping from a SID to an ID' SUP top AUXILIARY MUST sambaSID MAY ( uidNumber $ gidNumber ) )
    olcObjectClasses: {5}( 1.3.6.1.4.1.7165.2.2.9 NAME 'sambaSidEntry' DESC 'Structural Class for a SID' SUP top STRUCTURAL MUST sambaSID )
    olcObjectClasses: {6}( 1.3.6.1.4.1.7165.2.2.10 NAME 'sambaConfig' DESC 'Samba Configuration Section' SUP top AUXILIARY MAY description )
    olcObjectClasses: {7}( 1.3.6.1.4.1.7165.2.2.11 NAME 'sambaShare' DESC 'Samba Share Section' SUP top STRUCTURAL MUST sambaShareName MAY description )
    olcObjectClasses: {8}( 1.3.6.1.4.1.7165.2.2.12 NAME 'sambaConfigOption' DESC 'Samba Configuration Option' SUP top STRUCTURAL MUST sambaOptionName MAY ( sambaBoolOption $ sambaIntegerOption $ sambaStringOption $ sambaStringListOption $ description ) )
    olcObjectClasses: {9}( 1.3.6.1.4.1.7165.2.2.14 NAME 'sambaTrustPassword' DESC 'Samba Trust Password' SUP top STRUCTURAL MUST ( sambaDomainName $ sambaNTPassword $ sambaTrustFlags ) MAY ( sambaSID $ sambaPwdLastSet ) )
  '';

  sambaDomainName = "HOMESERVER";
  sambaSid = "S-1-5-21-3226911021-3024596977-3362438729";

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
          default = [ "users" ];
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

      users = (assignIds (cfg.ldap.openldap.users) 1000 "uid");

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

          {
            name = "samba_writers";
            type = "names";
          }

          {
            name = "users";
            type = "names";
          }

          {
            name = "admins";
            type = "names";
          }
        ]
        ++ cfg.ldap.openldap.groups
      ) 2000 "gid";

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
              file =
                if (builtins.isPath s.password) then s.password else (cfg.secret.directory + ("/" + s.password));
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
                "${pkgs.openldap}/etc/schema/nis.ldif"
                sambaSchemaLdif
              ];
            };

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

                  "{0}to attrs=sambaNTPassword,sambaPwdLastSet,sambaAcctFlags
                  by group.exact=\"cn=samba_writers,ou=groups,${basedn}\" write
                  by self write
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
          for OU in people services groups policies idmap; do
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

          echo "Configuring samba ..."
          apply_ldif "dn: sambaDomainName=${sambaDomainName},${basedn}
          objectClass: sambaDomain
          sambaDomainName: ${sambaDomainName}
          sambaSID: ${sambaSid}
          sambaNextRid: 1000"

          # ---------------------------------------------------------
          # PART B: Human Users (Create If Missing, Then Ignore)
          # ---------------------------------------------------------

          ${lib.concatMapStrings (
            user:
            ''
              HASH=$(${pkgs.openldap}/bin/slappasswd -s "${
                if user.password == null then user.name else user.password
              }")

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
