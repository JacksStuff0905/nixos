{
  lib,
  config,
  pkgs,
}:
let
  types = {
    host = types.submodule {
      options = with lib.types; {
        name = lib.mkOption { type = str; };
        ip = lib.mkOption { type = str; };

        protocol = lib.mkOption {
          type = enum [
            "http"
            "https"
          ];
        };

        port = lib.mkOption { type = int; };

        dns = lib.mkOption { type = str; };

        checkUser = lib.mkOption {
          readOnly = true;
          default = user: (user.services == null || builtins.elem name user.services);
        };
      };
    };

    user = types.submodule {
      options = with lib.types; {
        name = lib.mkOption { type = str; };
        admin = lib.mkOption { type = bool; };
        services = lib.mkOption {
          type = listOf str;
          default = null;
        };
      };
    };
  };

  mkHost =
    { name, url }:
    let
      urlparts = builtins.match "^([a-zA-Z][a-zA-Z0-9+.-]*)://([^:]+):([0-9]+)$" url;
    in
    {
      inherit name;

      protocol = builtins.elemAt urlparts 0;
      ip = builtins.elemAt urlparts 1;
      port = builtins.elemAt urlparts 2;

      dns = "${name}.${config.homeserver.domain}";
    };
in
{
  options.homeserver = {
    domain = lib.mkOption {
      type = lib.types.str;
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf types.host;
    };

    users = lib.mkOption {
      type = lib.types.attrsOf types.user;
    };
  };

  config.homeserver = {
    domain = "srv.lan";

    users = {
      jacek = {
        name = "jacek";
        admin = true;
      };

      test = {
        name = "test";
        admin = false;
      };
    };

    hosts = {
      proxy = mkHost {
        name = "proxy";
        url = "http://192.168.10.9:8080";
      };

      auth = mkHost {
        name = "auth";
        url = "http://192.168.10.7:9000";
      };

      nas = mkHost {
        name = "nas";
        url = "http://192.168.10.6:80";
      };

      browse = mkHost {
        name = "browse";
        url = "http://192.168.10.13:30051";
      };
    };
  };
}
