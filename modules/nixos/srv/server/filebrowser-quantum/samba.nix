{
  config,
  pkgs,
  lib,
  ...
}:

let
  name = "filebrowser-quantum";

  cfg = config.srv.server."${name}";

  usersDir = "${cfg.fbRoot}/Users";

  domainName = "HOMESERVER";
  domainSid = "S-1-5-21-3226911021-3024596977-3362438729";

  ldapBaseDn = lib.concatStringsSep "," (
    builtins.map (s: "dc=${s}") (lib.splitString "." cfg.samba.domain)
  );
  ldapBindDn = "cn=samba,ou=services,${ldapBaseDn}";

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

  sambaPkg = pkgs.samba.override {
    enableLDAP = true;
    # Optional: If you run into issues later, you might need this too,
    # but try with just enableLDAP first.
    #enableWinbind = true;
  };

  ldapURI = "ldap://${cfg.samba.ldapHost}:${toString cfg.samba.ldapPort}";

  ldapUserSuffix = "ou=people";
  ldapGroupSuffix = "ou=groups";
  ldapIdmapSuffix = "ou=idmap";
in
{
  options.srv.server."${name}" = {
    samba = {
      enable = lib.mkEnableOption "per-user samba server";

      domain = lib.mkOption {
        type = lib.types.str;
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      ldapHost = lib.mkOption {
        type = lib.types.str;
      };

      ldapPort = lib.mkOption {
        type = lib.types.int;
        default = 3890;
      };
      secret = {
        ldap-password = lib.mkOption {
          type = lib.types.path;
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.samba.enable) {
    age.secrets = {
      samba-ldap-password = {
        rekeyFile = cfg.samba.secret.ldap-password;
        owner = "root";
        group = "root";
        mode = "400";
      };
    };

    nixpkgs.overlays = [
      (final: pre: {
        samba = pre.samba.override {
          # This is the magic flag that tells Nix to compile Samba
          # with support for the ldapsam backend.
          enableLDAP = true;
        };
      })
    ];

    environment.systemPackages = [
      pkgs.samba
      pkgs.openldap
    ];

    systemd.services.samba-smbd.preStart = ''
      ${pkgs.samba}/bin/smbpasswd -w "$(cat ${config.age.secrets.samba-ldap-password.path})"
      ${pkgs.samba}/bin/net setlocalsid ${domainSid}
    '';

    services.samba = {
      enable = true;
      openFirewall = true;
      package = pkgs.samba;

      settings = {
        global = {
          security = "user";

          "netbios name" = "${domainName}";
          "workgroup" = "${domainName}";

          "passdb backend" = "ldapsam:${ldapURI}";
          "ldap suffix" = "${ldapBaseDn}";
          "ldap user suffix" = "${ldapUserSuffix}";
          "ldap group suffix" = "${ldapGroupSuffix}";
          "ldap admin dn" = "${ldapBindDn}";
          "ldap ssl" = "off";
          "ldap passwd sync" = "yes";
          "ldap idmap suffix" = "${ldapIdmapSuffix}";
          "ldap delete dn" = "yes";

          "unix password sync" = "yes";

          # ID mapping
          "idmap config * : backend" = "ldap";
          "idmap config * : range" = "10000-20000";
          "idmap config * : ldap_url" = "${ldapURI}";
          "idmap config * : ldap_base_dn" = "${ldapIdmapSuffix},${ldapBaseDn}";

          # Disable DC features
          "domain logons" = "no";
          "domain master" = "no";
          "local master" = "no";
          "preferred master" = "no";

          # Logging
          "log file" = "/var/log/samba/log.%m";
          "max log size" = 1000;
          "log level" = 2;
        };

        test = {
          "path" = "/mnt/filebrowser/test";
          browseable = "yes";
          "read only" = "no";
          "valid users" = "@users";
          "create mask" = "0664";
          "directory mask" = "0775";
          "force group" = "users";
        };

        # 3. The Dynamic Share
        "users" =
          let
            create-samba-home = pkgs.writeShellScript "create-samba-home" ''
              # %U is passed as the first argument ($1)
              USERNAME="$1"

              # Sanity check: prevent empty username
              if [ -z "$USERNAME" ]; then exit 1; fi

              TARGET_DIR="${usersDir}/$USERNAME"

              if [ ! -d "$TARGET_DIR" ]; then
                # Log to journald so you can see it happened
                echo "Auto-creating SMB home for user: $USERNAME" | logger -t smb-mkdir

                mkdir -p "$TARGET_DIR"
                
                # Set ownership to the Filebrowser system user
                # This ensures Filebrowser can read what Samba created
                chown filebrowser:filebrowser "$TARGET_DIR"
                
                # Standard directory permissions
                chmod 755 "$TARGET_DIR"
              fi
            '';
          in
          {
            comment = "User drives";
            path = "${usersDir}/%S";
            browseable = false;
            "read only" = false;
            "valid users" = "%S";
            "create mask" = "0600";
            "directory mask" = "0700";
          };
      };
    };

    users.ldap = {
      enable = true;
      server = "${ldapURI}";
      base = ldapBaseDn;
      bind = {
        distinguishedName = ldapBaseDn;
        passwordFile = config.age.secrets.samba-ldap-password.path;
      };
      daemon = {
        enable = true; # This enables nslcd
      };
    };

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

    systemd.tmpfiles.rules = [
      "d /var/log/samba 0750 root root -"
      "d ${usersDir} 0755 root root -"
    ];

    security.pam.services.samba = {
      # Enable LDAP authentication for Samba's PAM
      text = lib.mkDefault ''
        auth      required  pam_env.so
        auth      sufficient ${pkgs.pam_ldap}/lib/security/pam_ldap.so
        auth      required  pam_unix.so try_first_pass
        account   sufficient ${pkgs.pam_ldap}/lib/security/pam_ldap.so
        account   required  pam_unix.so
        password  sufficient ${pkgs.pam_ldap}/lib/security/pam_ldap.so
        password  required  pam_unix.so try_first_pass
        session   required  pam_unix.so
        session   optional  ${pkgs.pam_ldap}/lib/security/pam_ldap.so
      '';
    };

    networking.firewall = lib.mkIf cfg.samba.openFirewall {
      allowedTCPPorts = [
        139
        445
      ];
      allowedUDPPorts = [
        137
        138
      ];
    };
  };
}
