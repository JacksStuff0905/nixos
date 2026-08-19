{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.srv.ldap;
  serverUrl = "ldap://192.168.10.7:3890";

  base = "dc=srv,dc=lan";
  bindDN = "cn=readonly,ou=services,dc=srv,dc=lan";
in
{
  options.srv.ldap = {
    enable = lib.mkEnableOption "Enable ldap auth module";
    overrideHomeDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.bind-password = {
      rekeyFile = ../../../secrets/ldap-users/readonly-password.age;
      mode = "0600";
      owner = "nslcd";
      group = "nslcd";
    };

    users.ldap = {
      enable = true;
      nsswitch = true;
      loginPam = true;

      server = serverUrl;

      daemon.enable = true;
      daemon.extraConfig = lib.mkIf (cfg.overrideHomeDir != null) ''
        map passwd homeDirectory "${cfg.overrideHomeDir}/$uid"
      '';

      base = base;
      bind = {
        distinguishedName = bindDN;
        passwordFile = config.age.secrets.bind-password.path;
      };
    };

    users.groups.nslcd = {
    };

    users.users.nslcd = {
      isSystemUser = true;
      group = "nslcd";
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
  };
}
