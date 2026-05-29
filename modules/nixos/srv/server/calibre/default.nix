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
  server-port = 8080;

  basedn = builtins.concatStringsSep "," (
    builtins.map (d: "dc=${d}") (lib.splitString "." cfg.auth.ldap.domain)
  );

  cwa_default_settings = {
    "auto_metadata_fetch_enabled" = 0;
    "auto_metadata_smart_application" = 0;
    "auto_convert_retained_formats" = "epub,mobi";
  };
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    library = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    server = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
    frontends = {
      configPath = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/calibre/calibre-web-config";
      };

      calibre-web = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      calibre-web-automated = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        book-ingest = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/calibre/ingest";
        };
        plugins = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/calibre/plugins";
        };
        settings = lib.mkOption {
          type = lib.types.attrs;
          default = cwa_default_settings;
        };
      };
    };
    auth = {
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
          default = "Remote-User";
        };

        email = lib.mkOption {
          type = lib.types.str;
          default = "Remote-Email";
        };

        groups = lib.mkOption {
          type = lib.types.str;
          default = "Remote-Groups";
        };

        admin-groups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "netadmins"
          ];
        };
      };

      ldap = {
        host = lib.mkOption {
          type = lib.types.str;
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 3890;
        };
        domain = lib.mkOption {
          type = lib.types.str;
        };
        username = lib.mkOption {
          type = lib.types.str;
        };
        group = lib.mkOption {
          type = lib.types.str;
        };
        passwordFile = lib.mkOption {
          type = lib.types.path;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      nixpkgs.overlays = [
        (final: prev: {
          calibre-web = prev.calibre-web.overrideAttrs (oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              ${pkgs.gawk}/bin/awk '
                        /^def load_user_from_reverse_proxy_header\(req\):/ {
                          print "def load_user_from_reverse_proxy_header(req):"
                          print "    import logging"
                          print "    ROLE_ADMIN = 1  # Bitmask for admin role"
                          print "    ADMIN_GROUPS = [${
                            builtins.concatStringsSep ", " (map (g: ''\"${g}\"'') cfg.auth.proxy-headers.admin-groups)
                          }]"
                          print "    rp_header_name = config.config_reverse_proxy_login_header_name"
                          print "    logging.warning(\"PROXY AUTH: Looking for header: %s\", rp_header_name)"
                          print "    if rp_header_name:"
                          print "        rp_header_username = req.headers.get(rp_header_name)"
                          print "        rp_header_email = req.headers.get(\"${cfg.auth.proxy-headers.email}\", \"\")"
                          print "        rp_header_groups = req.headers.get(\"${cfg.auth.proxy-headers.groups}\", \"\")"
                          print "        logging.warning(\"PROXY AUTH: Got username: %s, groups: %s\", rp_header_username, rp_header_groups)"
                          print "        groups = set(g.strip() for g in rp_header_groups.split(\",\") if g.strip())"
                          print "        is_admin = bool(groups & set(ADMIN_GROUPS))"
                          print "        logging.warning(\"PROXY AUTH: User groups: %s, Admin groups: %s, Is admin: %s\", groups, ADMIN_GROUPS, is_admin)"
                          print "        if rp_header_username:"
                          print "            user = ub.session.query(ub.User).filter(func.lower(ub.User.name) == rp_header_username.lower()).first()"
                          print "            logging.warning(\"PROXY AUTH: Existing user: %s\", user)"
                          print "            if user:"
                          print "                if is_admin and not (user.role & ROLE_ADMIN):"
                          print "                    user.role |= ROLE_ADMIN"
                          print "                    ub.session_commit(\"Granted admin via group\")"
                          print "                    logging.warning(\"PROXY AUTH: Granted admin to user\")"
                          print "                elif not is_admin and (user.role & ROLE_ADMIN):"
                          print "                    user.role &= ~ROLE_ADMIN"
                          print "                    ub.session_commit(\"Revoked admin via group\")"
                          print "                    logging.warning(\"PROXY AUTH: Revoked admin from user\")"
                          print "                [limiter.limiter.storage.clear(k.key) for k in limiter.current_limits]"
                          print "                return user"
                          print "            logging.warning(\"PROXY AUTH: Creating new user: %s\", rp_header_username)"
                          print "            new_user = ub.User()"
                          print "            new_user.name = rp_header_username"
                          print "            new_user.password = \"\""
                          print "            new_user.email = rp_header_email"
                          print "            new_user.role = config.config_default_role"
                          print "            if is_admin:"
                          print "                new_user.role |= ROLE_ADMIN"
                          print "                logging.warning(\"PROXY AUTH: New user will be admin\")"
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

      users.groups.calibre-data = {
        gid = 3003;
      };

      users.users.calibre-web = {
        isSystemUser = true;
        group = "calibre-data";
      };

      users.users.calibre = {
        isSystemUser = true;
        uid = 3002;
        group = "calibre-data";
      };

      /*
        networking.firewall.allowedTCPPorts = [
                web-port
              ];
      */

      systemd.tmpfiles.rules = [
        "d /var/empty/.config/calibre 0775 calibre calibre-data -"
        "d ${cfg.library} 0775 calibre calibre-data -"
        "Z ${cfg.library} 0775 calibre calibre-data -"
        "d ${cfg.frontends.configPath} 0775 calibre calibre-data -"
      ];

      environment.systemPackages = [
        pkgs.calibre
      ]
      ++ (
        if (cfg.auth.enable && cfg.auth.mode == "ldap") then
          [
            pkgs.python313Packages.python-ldap
            pkgs.python313Packages.flask-simpleldap
          ]
        else
          [ ]
      );

      age.secrets = {
        ldap-password = lib.mkIf (cfg.auth.mode == "ldap") {
          rekeyFile = cfg.auth.ldap.passwordFile;
          owner = "calibre";
          group = "calibre-data";
          mode = "660";
        };
      };

      services.calibre-web = {
        enable = cfg.frontends.calibre-web.enable;
        listen.ip = "0.0.0.0";
        listen.port = web-port;
        options = {
          calibreLibrary = cfg.library;
          enableBookConversion = true;
          enableBookUploading = true;
          reverseProxyAuth = lib.mkIf (cfg.auth.enable && cfg.auth.mode == "proxy") {
            enable = true;
            header = cfg.auth.proxy-headers.username;
          };
        };
      };

      services.calibre-server = {
        enable = cfg.server.enable;
        host = "0.0.0.0";
        port = server-port;
        user = "calibre";
        group = "calibre-data";
        openFirewall = true;
        libraries = [ cfg.library ];
      };
    })
    (lib.mkIf cfg.frontends.calibre-web-automated.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.frontends.calibre-web-automated.book-ingest} 0775 calibre calibre-data -"
        "d ${cfg.frontends.calibre-web-automated.plugins} 0775 calibre calibre-data -"
      ];

      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
      };

      networking.firewall.interfaces =
        let
          matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
        in
        {
          "${matchAll}".allowedUDPPorts = [ 53 ];
        };

      virtualisation.oci-containers.backend = "podman";

      virtualisation.oci-containers.containers."calibre-web-automated" = {
        image = "ghcr.io/new-usemame/calibre-web-nextgen:latest";
        environment = {
          #"HARDCOVER_TOKEN" = "your_hardcover_api_key_here";
          "NETWORK_SHARE_MODE" = "true";
          "PGID" = "3003";
          "PUID" = "3002";
          "TZ" = "Europe/Warsaw";
          "CWA_PORT_OVERRIDE" = "${toString web-port}";
        };
        volumes = [
          "${cfg.frontends.configPath}:/config:rw"
          "${cfg.frontends.calibre-web-automated.book-ingest}:/cwa-book-ingest:rw"
          "${cfg.library}:/calibre-library:rw"
          "${cfg.frontends.calibre-web-automated.plugins}:/config/.config/calibre/plugins:rw"
        ];
        ports = [
          "${toString web-port}:${toString web-port}/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=calibre-web-automated"
          "--network=calibre-web-automated_default"
          "--cpus=0"
          "--memory=0"
          "--ulimit=nofile=65535:65535"
        ];
      };

      systemd.services.podman-calibre-web-automated-password-setup = {
        before = [ "calibre-web.service" ];
        wantedBy = [ "multi-user.target" ];
      };

      systemd.services."podman-calibre-web-automated" =
        let
          mkSettings =
            set:
            lib.concatStringsSep ", " (lib.flatten (lib.mapAttrsToList (n: v: "${n} = '${toString v}'") set));

          settings = lib.concatStringsSep ", " (
            lib.flatten (
              [
                "config_use_https = 0"
              ]
              ++ lib.optional (cfg.auth.mode == "ldap") [
                "config_ldap_provider_url = '${cfg.auth.ldap.host}'"
                "config_ldap_port = '${toString cfg.auth.ldap.port}'"
                "config_ldap_port = '${toString cfg.auth.ldap.port}'"
                "config_ldap_authentication = 2" # Simple auth
                "config_ldap_serv_username = 'cn=${cfg.auth.ldap.username},ou=services,${basedn}'"
                "config_ldap_dn = '${basedn}'"
                "config_ldap_group_name = '${cfg.auth.ldap.group}'"
              ]
            )
          );

          cwa_settings = mkSettings (cwa_default_settings // cfg.frontends.calibre-web-automated.settings);
        in
        {
          # Apply settings
          preStart = ''
            PYTHON_WITH_CRYPTO="${pkgs.python3.withPackages (ps: [ ps.cryptography ])}/bin/python3"
            KEY_FILE="${cfg.frontends.configPath}/.key"

            if [ -f "$KEY_FILE" ]; then
              KEY="$(cat "$KEY_FILE")"
              LDAP_PASSWORD="$(cat ${config.age.secrets.ldap-password.path})"
              
              # Use python to encrypt the password with the found key
              ENCRYPTED=$($PYTHON_WITH_CRYPTO -c "from cryptography.fernet import Fernet; print(Fernet('$KEY').encrypt(b'$LDAP_PASSWORD').decode())")
              
              ${pkgs.sqlite}/bin/sqlite3 ${cfg.frontends.configPath}/app.db  \
                "update settings set config_ldap_serv_password_e = '$ENCRYPTED', config_ldap_serv_password = ''\'''\';"
            fi

            ${pkgs.sqlite}/bin/sqlite3 ${cfg.frontends.configPath}/app.db "update settings set ${settings};"

            ${pkgs.sqlite}/bin/sqlite3 ${cfg.frontends.configPath}/cwa.db "update cwa_settings set ${cwa_settings};"
          '';

          postStart = "";

          # Ensure cryptography is available for the script
          path = [ pkgs.python3Packages.cryptography ];

          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };
          after = [
            "podman-network-calibre-web-automated_default.service"
          ];
          requires = [
            "podman-network-calibre-web-automated_default.service"
          ];
          partOf = [
            "podman-compose-calibre-web-automated-root.target"
          ];
          wantedBy = [
            "podman-compose-calibre-web-automated-root.target"
          ];
        };

      systemd.services."podman-network-calibre-web-automated_default" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "podman network rm -f calibre-web-automated_default";
        };
        script = ''
          podman network inspect calibre-web-automated_default || podman network create calibre-web-automated_default
        '';
        partOf = [ "podman-compose-calibre-web-automated-root.target" ];
        wantedBy = [ "podman-compose-calibre-web-automated-root.target" ];
      };

      systemd.targets."podman-compose-calibre-web-automated-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    })
  ];
}
