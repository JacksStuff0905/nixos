{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "calibre";

  cfg = config.srv.server."${name}";
  web-port = 8083;
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    library = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    authentik = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      mode = lib.mkOption {
        type = lib.types.enum [
          "proxy"
          "ldap"
        ];
        default = "proxy";
      };

      proxy-headers = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "X-authentik-username";
        };

        email = lib.mkOption {
          type = lib.types.str;
          default = "X-authentik-email";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = [
      (final: prev: {
        calibre-web = prev.calibre-web.overrideAttrs (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            ${pkgs.gawk}/bin/awk '
                      /^def load_user_from_reverse_proxy_header\(req\):/ {
                        print "def load_user_from_reverse_proxy_header(req):"
                        print "    import logging"
                        print "    rp_header_name = config.config_reverse_proxy_login_header_name"
                        print "    logging.warning(\"PROXY AUTH: Looking for header: %s\", rp_header_name)"
                        print "    if rp_header_name:"
                        print "        rp_header_username = req.headers.get(rp_header_name)"
                        print "        rp_header_email = req.headers.get(\"${cfg.authentik.proxy-headers.email}\", \"\")"
                        print "        logging.warning(\"PROXY AUTH: Got username: %s\", rp_header_username)"
                        print "        if rp_header_username:"
                        print "            user = ub.session.query(ub.User).filter(func.lower(ub.User.name) == rp_header_username.lower()).first()"
                        print "            logging.warning(\"PROXY AUTH: Existing user: %s\", user)"
                        print "            if user:"
                        print "                [limiter.limiter.storage.clear(k.key) for k in limiter.current_limits]"
                        print "                return user"
                        print "            # Auto-create user with default settings"
                        print "            logging.warning(\"PROXY AUTH: Creating new user: %s\", rp_header_username)"
                        print "            new_user = ub.User()"
                        print "            new_user.name = rp_header_username"
                        print "            new_user.password = \"\""
                        print "            new_user.email = rp_header_email"
                        print "            new_user.role = config.config_default_role"
                        print "            new_user.sidebar_view = config.config_default_show"
                        print "            new_user.locale = config.config_default_locale"
                        print "            new_user.default_language = config.config_default_language"
                        print "            new_user.denied_tags = config.config_denied_tags"
                        print "            new_user.allowed_tags = config.config_allowed_tags"
                        print "            new_user.denied_column_value = config.config_denied_column_value"
                        print "            new_user.allowed_column_value = config.config_allowed_column_value"
                        print "            ub.session.add(new_user)"
                        print "            try:"
                        print "                ub.session_commit(\"Created user via reverse proxy\")"
                        print "                logging.warning(\"PROXY AUTH: User created successfully\")"
                        print "                return new_user"
                        print "            except Exception as e:"
                        print "                logging.warning(\"PROXY AUTH: Failed to create: %s\", e)"
                        print "                ub.session.rollback()"
                        print "    return None"
                        print ""
                        skip = 1
                        next
                      }
                      skip && /^def |^class / {
                        skip = 0
                      }
                      !skip { print }
                      ' src/calibreweb/cps/usermanagement.py > src/calibreweb/cps/usermanagement.py.new
                      mv src/calibreweb/cps/usermanagement.py.new src/calibreweb/cps/usermanagement.py
          '';
        });
      })
    ];

    networking.firewall.allowedTCPPorts = [
      web-port
    ];

    environment.systemPackages = [
      pkgs.calibre
    ]
    ++ (
      if (cfg.authentik.enable && cfg.authentik.mode == "ldap") then
        [
          pkgs.python313Packages.python-ldap
          pkgs.python313Packages.flask-simpleldap
        ]
      else
        [ ]
    );

    services.calibre-web = {
      enable = true;
      listen.ip = "0.0.0.0";
      listen.port = web-port;
      options = {
        calibreLibrary = cfg.library;
        enableBookConversion = true;
        enableBookUploading = true;
        reverseProxyAuth = lib.mkIf (cfg.authentik.enable && cfg.authentik.mode == "proxy") {
          enable = true;
          header = cfg.authentik.proxy-headers.username;
        };
      };
    };
  };
}
