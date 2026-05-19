{ pkgs, basedn, sambaSID, ... }:
let
  script = user: ''
  HASH=$(${pkgs.openldap}/bin/slappasswd -s "${
    if user.password == null then user.name else user.password
  }")

  # Upsert user ${user.name}
  # Check if user exists
  if ${pkgs.openldap}/bin/ldapsearch -H ldapi:/// -Y EXTERNAL -LLL \
      -b "uid=${user.name},ou=people,${basedn}" -s base "(objectClass=*)" dn 2>/dev/null | grep -q "^dn:"; then
    echo "User ${user.name} exists, updating attributes (except passwords)..."
    # Use ldapmodify to REPLACE attributes you want to control declaratively
    # We purposefully omit userPassword and sambaNTPassword here
    ${pkgs.openldap}/bin/ldapmodify -H ldapi:/// -Y EXTERNAL <<EOF
dn: uid=${user.name},ou=people,${basedn}
changetype: modify
replace: cn
cn: ${user.name}
-
replace: sn
sn: ${user.name}
-
replace: uidNumber
uidNumber: ${toString user.uid}
-
replace: homeDirectory
homeDirectory: /home/${user.name}
-
replace: mail
mail: ${user.email}
-
replace: sambaSID
sambaSID: ${sambaSID}-${toString user.uid}
EOF
  else
    echo "User ${user.name} missing, creating..."
    ${pkgs.openldap}/bin/ldapadd -H ldapi:/// -Y EXTERNAL 2>&1 <<EOF
dn: uid=${user.name},ou=people,${basedn}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: sambaSamAccount
uid: ${user.name}
cn: ${user.name}
sn: ${user.name}
uidNumber: ${toString user.uid}
gidNumber: ${toString user.uid}
homeDirectory: /home/${user.name}
mail: ${user.email}
loginShell: /bin/bash
sambaSID: ${sambaSID}-${toString user.uid}
userPassword: $HASH
sambaNTPassword: 
EOF
  fi

  '';
in
script
