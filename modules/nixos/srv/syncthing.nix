{
  config,
  lib,
  pkgs,
  common,
  ...
}:

let
  cfg = config.srv.syncthing;
  jsonFormat = pkgs.formats.json { };

  mkDeviceIds = names: builtins.map (n: { deviceID = hostDevices."${n}".id; }) names;

  mkJsonDevices =
    devices:
    lib.mapAttrsToList (
      name: device:
      (removeAttrs device [ "id" ])
      // {
        deviceID = device.id;
        inherit name;
      }
    ) devices;

  mkJsonFolders =
    folders:
    lib.mapAttrsToList (
      name: folder:
      (removeAttrs folder [ "id" ])
      // {
        id = name;
        label = name;
      }
    ) folders;

  hostDevices = builtins.foldl' (sum: dev: sum // dev) { } (
    lib.mapAttrsToList (
      n: h:
      lib.mapAttrs' (u: v: {
        name = "${u}@${h.host.hostName or n}";
        value.id = v.id;
      }) (lib.filterAttrs (n: u: u.id != null) h.srv.syncthing.users)
    ) (lib.filterAttrs (n: h: h.srv.syncthing.enable && h != config) common.nixosHosts)
  );

  folderHosts =
    f:
    builtins.foldl' (sum: dev: sum ++ dev) [ ] (
      lib.mapAttrsToList (
        n: h:
        (lib.mapAttrsToList (un: u: "${un}@${h.host.hostName}") (
          lib.filterAttrs (
            un: u:
            let
              folders = u.folders;
            in
            u.id != null && folders ? "${f}" && folders."${f}" ? enable && folders."${f}".enable
          ) h.srv.syncthing.users
        ))
      ) (lib.filterAttrs (n: h: h.srv.syncthing.enable && h != config) common.nixosHosts)
    );

  types = {
    mkFolder =
      with lib;
      {
        enable ? false,
        path ? "",
        versioning ? {
          type = "simple";
          params.keep = "3";
        },
      }:
      lib.types.submodule {
        options = with lib.types; {
          enable = mkOption {
            example = true;
            description = "Whether to enable this folder";
            type = bool;
            default = enable;
          };

          path = mkOption {
            type = str;
            default = path;
          };

          versioning = lib.mkOption {
            type = attrs;
            default = versioning;
          };

          devices = {
            includeHosts = mkOption {
              type = bool;
              default = true;
            };
            extraDevices = mkOption {
              type = listOf str;
              default = [ ];
            };
          };
        };
      };
  };

  defaultSettingsFile = pkgs.writeText "syncthing-default.json" (builtins.toJSON cfg.defaultSettings);
  userSettings =
    user:
    if cfg.users ? "${user}" then
      (
        let
          u = cfg.users."${user}";
        in
        builtins.toJSON {
          devices = mkJsonDevices (
            (if u.devices.includeHosts then hostDevices else { }) // u.devices.extraDevices
          );

          folders = mkJsonFolders (
            builtins.mapAttrs (n: f: {
              path = f.path;
              versioning = f.versioning;
              devices = mkDeviceIds (
                (if f.devices.includeHosts then (folderHosts "${n}") else { }) ++ f.devices.extraDevices
              );
            }) (lib.filterAttrs (n: f: f.enable) u.folders)
          );
        }
      )
    else
      "{}";

  syncthingApplyJsonConfig = pkgs.writeShellScriptBin "syncthing-apply-json-config" ''
    SOCKET="$1"
    JSON_FILE="$2"
    USER="$3"
    CONFIG_DIR="$(eval echo "${cfg.configDir}/$USER/.config/syncthing")"

    if [ ! -f "$CONFIG_DIR/config.xml" ]; then
      ${pkgs.syncthing}/bin/syncthing generate --home="$CONFIG_DIR"
    fi

    while [ ! -S "$SOCKET" ]; do sleep 0.2; done

    API_KEY="$(grep -oP '(?<=<apikey>)[^<]+' "$CONFIG_DIR/config.xml")"

    ${pkgs.curl}/bin/curl --unix-socket "$SOCKET" \
      -H "X-API-Key: $API_KEY" \
      http://localhost/rest/config | ${pkgs.jq}/bin/jq > "$CONFIG_DIR/tmp-config.json"

    USER_UID=$(id -u "$USER")
    SYNC_PORT=$((${toString cfg.baseSyncPort} + (USER_UID % 40000)))

    SELF_ID="$(${pkgs.curl}/bin/curl -sIo /dev/null http://localhost/rest/noauth/health --unix-socket "$SOCKET" -w '%header{X-Syncthing-Id}')"

    ${pkgs.jq}/bin/jq \
      --arg socket "unix://$SOCKET" \
      --arg selfID "$SELF_ID" \
      --arg deviceName "$USER@$(${pkgs.hostname}/bin/hostname)" \
      --arg syncPort "tcp://0.0.0.0:$SYNC_PORT" \
      --slurpfile nixConfig "$JSON_FILE" \
      '(. // {}) * ($nixConfig[0] // {}) | .gui.address = $socket | .options.listenAddresses = [$syncPort] | .devices |= map(
        if .deviceID == $selfID then .name = $deviceName
        else .
        end
      )' \
      "$CONFIG_DIR/tmp-config.json" > "$CONFIG_DIR/new-config.json"

    ${pkgs.curl}/bin/curl -X PUT \
      --unix-socket "$SOCKET" \
      -H "X-API-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -d @$CONFIG_DIR/new-config.json \
      http://localhost/rest/config
    rm -f "$CONFIG_DIR/tmp-config.json" "$CONFIG_DIR/new-config.json"

    # Restart
    #${pkgs.curl}/bin/curl -X POST \
    #  --unix-socket "$SOCKET" \
    #  -H "X-API-Key: $API_KEY" \
    #  http://localhost/rest/system/restart
  '';

  syncthingWrapper = pkgs.writeShellScriptBin "syncthing-wrapper" ''
    set -eu

    USER=$1
    CONFIG_DIR="$(eval echo "${cfg.configDir}/$USER/.config/syncthing")"
    SOCKET="/run/syncthing-users/$USER.sock"

    touch "$SOCKET"
    chown $USER "$SOCKET"

    if [ ! -f "$CONFIG_DIR/config.xml" ]; then
      ${pkgs.syncthing}/bin/syncthing generate --home="$CONFIG_DIR"
    fi

    (
      while [ ! -S "$SOCKET" ]; do sleep 0.2; done
      chmod 666 "$SOCKET"
    ) &

    exec ${pkgs.syncthing}/bin/syncthing serve \
      --home="$CONFIG_DIR" \
      --gui-address="unix://$SOCKET" \
      --no-browser --no-restart
  '';
in
{
  options.srv.syncthing = {
    enable = lib.mkEnableOption "Enable syncthing module";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.host.user.name;
    };

    proxyPort = lib.mkOption {
      type = lib.types.int;
      default = 8384;
    };

    openGUIFirewall = lib.mkEnableOption "open proxy port";

    auth = {
      group = lib.mkOption {
        type = lib.types.str;
        default = "syncthing-users";
      };
      applyGroup = lib.mkEnableOption "add users to group";
      mode = lib.mkOption {
        type = lib.types.enum [
          "proxy"
          "pam"
        ];
        default = "pam";
        description = ''
          "proxy" relies on an upstream reverse proxy (like Traefik) passing a header.
          "pam" uses Nginx HTTP Basic Auth to authenticate against local Linux users.
        '';
      };

      proxyHeader = lib.mkOption {
        type = lib.types.str;
        default = "X-Forwarded-User";
        description = "Header used in 'proxy' auth.mode to determine the user.";
      };
    };

    baseSyncPort = lib.mkOption {
      type = lib.types.int;
      default = 20000;
      description = "Base port for Syncthing sync traffic. Calculated as basePort + (UID % 40000).";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "The domain Nginx should listen to (e.g. sync.mydomain.com or localhost)";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/home";
    };

    defaultSettings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = "Declarative settings (follows Syncthing JSON schema) applied to ANY spawned user.";
    };

    users = lib.mkOption {
      description = "Specific declarative settings for explicitly named users.";
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            keySecret = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
            };

            cert = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            certFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
            };

            devices = {
              includeHosts = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              extraDevices = lib.mkOption {
                type = lib.types.attrsOf lib.types.attrs;
                default = { };
              };
            };

            folders = {
              secret = lib.mkOption {
                type = types.mkFolder {
                  enable = true;
                  path = "~/Secret";
                };
                default = { };
              };

              projects = lib.mkOption {
                type = types.mkFolder {
                  enable = false;
                };
                default = { };
              };
            };

            settings = lib.mkOption {
              type = jsonFormat.type;
              default = { };
              description = "Declarative settings for this specific user.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {

    users.users = lib.mkMerge [
      (lib.mkIf cfg.auth.applyGroup (
        lib.mapAttrs (n: v: { extraGroups = [ "${cfg.auth.group}" ]; }) cfg.users
      ))
    ];

    systemd.tmpfiles.rules = [
      "d /run/syncthing-users 1777 root ${cfg.auth.group} -"
      "z /run/syncthing-users 1777 root ${cfg.auth.group} -"
      "d ${cfg.configDir} 0770 root ${cfg.auth.group} -"
    ];

    age.secrets = lib.mapAttrs' (n: v: {
      name = "syncthing-key-${n}";
      value = {
        rekeyFile = v.keySecret;
        owner = n;
        group = cfg.auth.group;
        mode = "0600";
      };
    }) cfg.users;

    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (n: v: {
        name = "syncthing-provision-user-${n}";
        value =
          let
            cert =
              if v.certFile == null then
                "${
                  (builtins.toFile "cert.pem" (
                    lib.strings.trim (builtins.replaceStrings [ "\t" "\r" ] [ "" "" ] v.cert) + "\n"
                  ))
                }"
              else
                v.certFile;
          in
          {
            description = "Wait for specific user to exist before running script";

            after = [
              "nss-user-lookup.target"
              "network-online.target"
              "syncthing-user@${n}.service"
            ];
            wants = [
              "nss-user-lookup.target"
              "network-online.target"
              "syncthing-user@${n}.service"
            ];

            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              TimeoutStartSec = "60s";
            };

            script = ''
              set -efu

              CONFIG_DIR="$(eval echo "${cfg.configDir}/${n}/.config/syncthing")"
              SOCKET="/run/syncthing-users/${n}.sock"

              if [ ! -f "$CONFIG_DIR/config.xml" ]; then
                ${pkgs.syncthing}/bin/syncthing generate --home="$CONFIG_DIR"
              fi

              while [ ! -S "$SOCKET" ]; do sleep 0.2; done

              API_KEY="$(${pkgs.sudo}/bin/sudo -u "$USER" grep -oP '(?<=<apikey>)[^<]+' "$CONFIG_DIR/config.xml")"

              install -dm700 -o ${n} -g ${cfg.auth.group} $CONFIG_DIR
              ${
                if (cert != null || v.keySecret != null) then
                  ''
                    ${lib.optionalString (cert != null) ''
                      install -Dm644 -o ${n} -g ${cfg.auth.group} ${toString cert} $CONFIG_DIR/cert.pem
                    ''}
                    ${lib.optionalString (v.keySecret != null) ''
                      install -Dm600 -o ${n} -g ${cfg.auth.group} ${
                        toString config.age.secrets."syncthing-key-${n}".path
                      } $CONFIG_DIR/key.pem
                    ''}
                  ''
                else
                  ""
              }

              if [ ! -f "$CONFIG_DIR/config.xml" ]; then
                ${pkgs.sudo}/bin/sudo -u "${n}" ${pkgs.syncthing}/bin/syncthing generate --home="$CONFIG_DIR"

                ${pkgs.curl}/bin/curl -X POST \
                  --unix-socket "$SOCKET" \
                  -H "X-API-Key: $API_KEY" \
                  http://localhost/rest/system/restart
              fi

              DECLARATIVE_JSON="$(${pkgs.jq}/bin/jq '. * $p' ${defaultSettingsFile} --argjson p '${userSettings n}')"
              echo "$DECLARATIVE_JSON" > "$CONFIG_DIR/decl-config.json"

              ${lib.getExe syncthingApplyJsonConfig} "$SOCKET" "$CONFIG_DIR/decl-config.json" "${n}"
              rm "$CONFIG_DIR/decl-config.json"
            '';
          };
      }) cfg.users)

      {
        "syncthing-user@" = {
          description = "Dynamic Syncthing Instance for %i";
          after = [ "network.target" ];
          serviceConfig = {
            User = "%i";
            Group = cfg.auth.group;
            ExecStart = "${syncthingWrapper}/bin/syncthing-wrapper %i";
            ExecStartPost = ''${pkgs.bash}/bin/bash -c "${lib.getExe syncthingApplyJsonConfig} /run/syncthing-users/%i.sock "${defaultSettingsFile}" %i"'';
            Restart = "always";
          };
        };

        ensure-syncthing = {
          description = "Ensure a syncthing instance for each user";
          path = [
            pkgs.sudo
            pkgs.getent
            pkgs.gawk
          ];
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = ''
            set -eu

            GROUP="${cfg.auth.group}"
            TEMPLATE="syncthing-user"

            current_users="$(ls /run/syncthing-users -1 | grep -oP "^[^\.]+(?=\.sock)" | sort)"

            target_users="$(getent group "$GROUP" | grep -oP "[^:]*" | awk 'NR==4' | grep -oP "[^,]+" | sort)"

            users_to_stop="$(comm -23 <(echo -n "$current_users") <(echo -n "$target_users"))"
            users_to_start="$(comm -13 <(echo -n "$current_users") <(echo -n "$target_users"))"

            while IFS= read -r user; do
                if [[ -z "$user" ]]; then continue; fi
                systemctl stop "$TEMPLATE@$user.service"
            done <<< "$users_to_stop"

            while IFS= read -r user; do
                if [[ -z "$user" ]]; then continue; fi
                systemctl start "$TEMPLATE@$user.service"
            done <<< "$users_to_start"
          '';
        };

        nginx = {
          environment = {
            PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin";
          };

          serviceConfig = {
            SupplementaryGroups = [ "shadow" ];
            SystemCallFilter = lib.mkForce [
              "@system-service"
              "@setuid"
              "@file-system"
            ];
          };
        };
      }
    ];

    systemd.timers.ensure-syncthing = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "20s";
        OnUnitActiveSec = "20s";
        Unit = "ensure-syncthing.service";
      };
    };

    security.wrappers.unix_chkpwd = {
      source = "${pkgs.pam}/bin/unix_chkpwd";
      setuid = true;
      owner = "root";
      group = "root";
      permissions = "u+s,a+x";
    };

    security.pam.services.nginx = lib.mkIf (cfg.auth.mode == "pam") {
      unixAuth = true;
      setEnvironment = false;
      text = ''
        # Check group + exit early
        auth    required  pam_succeed_if.so  user ingroup ${cfg.auth.group}
        auth    required  pam_unix.so        nodelay
        account required  pam_succeed_if.so  user ingroup ${cfg.auth.group}
        account required  pam_unix.so
      '';
    };

    users.groups.syncthing = { };
    users.groups."${cfg.auth.group}" = lib.mkIf cfg.auth.applyGroup { };

    security.polkit.enable = true;

    services.nginx = {
      enable = true;
      additionalModules = [
        pkgs.nginxModules.lua
        pkgs.nginxModules.pam
      ];

      group = "${cfg.auth.group}";

      appendHttpConfig = ''
        lua_package_path "${pkgs.luajitPackages.lua-resty-core}/lib/lua/5.1/?.lua;${pkgs.luajitPackages.lua-resty-lrucache}/lib/lua/5.1/?.lua;;";
      '';

      virtualHosts."${cfg.domain}" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = cfg.proxyPort;
          }
        ];

        locations."/" = {
          extraConfig = ''
            # --- AUTHENTICATION LOGIC ---
            ${
              if cfg.auth.mode == "pam" then
                ''
                  auth_pam "Syncthing Authentication (Use Linux Username/Password)";
                  auth_pam_service_name "nginx";
                  set $st_user $remote_user;
                ''
              else
                ''
                  # Translate header e.g., X-Forwarded-User -> $http_x_forwarded_user
                  set $st_user $http_${lib.replaceStrings [ "-" ] [ "_" ] (lib.toLower cfg.auth.proxyHeader)};
                  if ($st_user = "") {
                      return 401 "Unauthorized: No ${cfg.auth.proxyHeader} header found";
                  }
                ''
            }

            # --- PROXY TO UNIX SOCKET ---
            proxy_pass http://unix:/run/syncthing-users/$st_user.sock;

            # Necessary headers for Syncthing GUI to function properly
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };

    networking.firewall.allowedTCPPortRanges = [
      {
        from = cfg.baseSyncPort;
        to = cfg.baseSyncPort + 40000;
      }
    ];
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openGUIFirewall [ cfg.proxyPort ];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = cfg.baseSyncPort;
        to = cfg.baseSyncPort + 40000;
      }
    ];
  };
}
