{
  config,
  pkgs,
  lib,
  ...
}:

let
  name = "filebrowser-quantum";

  cfg = config.srv.server."${name}";

  ldapBaseDn = lib.concatStringsSep "," (
    builtins.map (s: "dc=${s}") (lib.splitString "." cfg.smb.domain)
  );
  ldapBindDn = "uid=admin,ou=people,${ldapBaseDn}";

  # Script to ensure user directory exists on first connection
  ensureUserDir = pkgs.writeShellScript "ensure-user-dir" ''
    USERNAME="$1"

    # Validate username to prevent path traversal
    if [[ ! "$USERNAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
      echo "Invalid username: $USERNAME" | ${pkgs.systemd}/bin/systemd-cat -t samba-provision -p err
      exit 1
    fi

    USER_DIR="${usersDir}/$USERNAME"

    if [ ! -d "$USER_DIR" ]; then
      echo "Creating directory for user: $USERNAME" | ${pkgs.systemd}/bin/systemd-cat -t samba-provision
      ${pkgs.coreutils}/bin/mkdir -p "$USER_DIR"
      ${pkgs.coreutils}/bin/mkdir -p "$USER_DIR"/{Documents,Downloads,Media}
      
      # Set ownership - using the filebrowser group for shared access
      ${pkgs.coreutils}/bin/chown -R "$USERNAME":filebrowser "$USER_DIR" 2>/dev/null || \
        ${pkgs.coreutils}/bin/chown -R filebrowser:filebrowser "$USER_DIR"
      
      ${pkgs.coreutils}/bin/chmod 2750 "$USER_DIR"
      ${pkgs.coreutils}/bin/chmod 2750 "$USER_DIR"/{Documents,Downloads,Media}
    fi

    exit 0
  '';
in
{
  options.srv.server."${name}" = {
    smb = {
      enable = lib.mkEnableOption "per-user smb server";

      domain = lib.mkOption {
        type = lib.types.str;
      };

      # LDAP connection details (consider using sops-nix or agenix for secrets)
      ldapHost = lib.mkOption {
        type = lib.types.str;
      };
      ldapPort = lib.mkOption {
        type = lib.types.int;
        default = 3890;
      };
    };

  };

  config = lib.mkIf (cfg.enable && cfg.smb.enable) {
    # We need nss-pam-ldapd to resolve LDAP users for Samba
    services.nslcd = {
      enable = true;
      config = ''
        uid nslcd
        gid nslcd

        uri ldap://${cfg.smb.ldapHost}:${toString cfg.smb.ldapPort}
        base ${ldapBaseDn}

        # Bind credentials
        binddn ${ldapBindDn}
        bindpw_file /run/secrets/ldap-bind-password

        # User mapping
        base passwd ou=people,${ldapBaseDn}
        base group ou=groups,${ldapBaseDn}
        base shadow ou=people,${ldapBaseDn}

        # Map lldap attributes to POSIX
        # lldap uses 'uid' for username, 'mail' for email
        map passwd uid uid
        map passwd gecos displayName
        map passwd homeDirectory "${usersDir}/$uid"
        map passwd loginShell /run/current-system/sw/bin/nologin

        # lldap doesn't have numeric UIDs by default, so we derive from DN
        # Alternatively, configure lldap to include uidNumber/gidNumber
        map passwd uidNumber uidNumber
        map passwd gidNumber gidNumber

        # Fallback GID for users without explicit group
        # nss_default_gid ${toString config.users.groups.filebrowser.gid}

        # Filter for valid users
        filter passwd (objectClass=person)
        filter group (objectClass=groupOfUniqueNames)

        # TLS (enable if lldap has TLS configured)
        # ssl start_tls
        # tls_reqcert demand
        # tls_cacertfile /etc/ssl/certs/ca-certificates.crt
      '';
    };

    # Add LDAP to NSS lookups
    system.nssDatabases = {
      passwd = [
        "files"
        "ldap"
      ];
      group = [
        "files"
        "ldap"
      ];
      shadow = [
        "files"
        "ldap"
      ];
    };

    services.samba = {
      enable = true;

      # Open firewall for SMB
      openFirewall = true;

      # Security settings
      securityType = "user";

      # Use LDAP as password backend
      # Note: NixOS doesn't have direct ldapsam passdb option,
      # we configure it in extraConfig

      extraConfig = ''
        # Server identification
        workgroup = WORKGROUP
        server string = NixOS File Server
        netbios name = FILESERVER

        # Security
        security = user
        map to guest = never
        guest account = nobody

        # LDAP passdb backend
        passdb backend = ldapsam:ldap://${ldapHost}:${toString ldapPort}
        ldap suffix = ${ldapBaseDn}
        ldap user suffix = ou=people
        ldap group suffix = ou=groups
        ldap admin dn = ${ldapBindDn}
        ldap ssl = off
        ldap passwd sync = yes

        # If lldap doesn't have Samba schema, use simple bind auth instead:
        # passdb backend = tdbsam
        # (and sync users separately - see alternative approach below)

        # Performance
        socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
        read raw = yes
        write raw = yes
        use sendfile = yes
        aio read size = 16384
        aio write size = 16384

        # macOS compatibility
        min protocol = SMB2
        vfs objects = fruit streams_xattr
        fruit:metadata = stream
        fruit:model = MacSamba
        fruit:posix_rename = yes
        fruit:veto_appledouble = no
        fruit:wipe_intentionally_left_blank_rfork = yes
        fruit:delete_empty_adfiles = yes

        # Logging
        log level = 2
        log file = /var/log/samba/log.%m
        max log size = 1000

        # Character encoding
        unix charset = UTF-8
        dos charset = CP850
      '';

      shares = {
        # ────────────────────────────────────────────────────────────
        # Dynamic per-user home directories
        # Users connect to \\server\username and get their own folder
        # ────────────────────────────────────────────────────────────
        homes = {
          comment = "User Personal Drive";
          path = "${userDataPath}/%U";
          browseable = false;
          writable = true;
          "valid users" = "%S";
          "create mask" = "0640";
          "directory mask" = "0750";
          "force group" = "filebrowser";

          # Create user directory on first access
          "root preexec" = "${ensureUserDir} %U";

          # Ensure files are accessible by filebrowser service too
          "inherit permissions" = true;
        };

        # ────────────────────────────────────────────────────────────
        # Optional: Shared space for all authenticated users
        # ────────────────────────────────────────────────────────────
        shared = {
          comment = "Shared Files";
          path = "/srv/filebrowser/shared";
          browseable = true;
          writable = true;
          "valid users" = "@filebrowser";
          "create mask" = "0660";
          "directory mask" = "2770";
          "force group" = "filebrowser";
        };
      };
    };

    # Ensure Samba service knows the LDAP password
    systemd.services.samba-smbd = {
      preStart = ''
        # Set LDAP admin password for Samba
        # This reads the password file and configures Samba's secrets.tdb
        ${pkgs.samba}/bin/smbpasswd -w "$(cat /run/secrets/ldap-bind-password)"
      '';
      serviceConfig = {
        # Ensure we can read the secrets file
        SupplementaryGroups = [ "secrets" ];
      };
    };

  };
}
