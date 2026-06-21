{
  config,
  pkgs,
  lib,
  ...
}:

let
  name = "samba";

  cfg = config.srv.server."${name}";

  domainName = "HOMESERVER";
  domainSid = "S-1-5-21-3226911021-3024596977-3362438729";

  ldapBaseDn = lib.concatStringsSep "," (
    builtins.map (s: "dc=${s}") (lib.splitString "." cfg.domain)
  );
  ldapBindDn = "cn=${cfg.ldapUser},ou=services,${ldapBaseDn}";

  ldapURI = "ldap://${cfg.ldapHost}:${toString cfg.ldapPort}";

  ldapUserSuffix = "ou=people";
  ldapGroupSuffix = "ou=groups";
  ldapIdmapSuffix = "ou=idmap";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "abstract LDAP-connected samba server";
    ldapUser = lib.mkOption {
      type = lib.types.str;
    };
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

    shares = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    # LDAP auth must be enabled
    srv.ldap.enable = lib.mkForce true;

    age.secrets = {
      samba-ldap-password = {
        rekeyFile = cfg.secret.ldap-password;
        owner = "root";
        group = "root";
        mode = "400";
      };
    };

    nixpkgs.overlays = [
      (final: pre: {
        samba = pre.samba.override {
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

    systemd.services.samba-smbd.serviceConfig = {
      User = "root";
      Group = "root";
    };

    systemd.services.samba-nmbd.serviceConfig = {
      User = "root";
      Group = "root";
    };

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
          "idmap config * : range" = "100000-199999"; # Cant overlap LDAP
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
          "log level" = 10;
        };
      }
      // cfg.shares;
    };

    systemd.tmpfiles.rules = [
      "d /var/log/samba 0750 root root -"
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

    networking.firewall = lib.mkIf cfg.openFirewall {
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
