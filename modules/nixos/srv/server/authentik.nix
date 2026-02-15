{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  name = "authentik";

  cfg = config.srv.server."${name}";
in
{
  imports = [
    inputs.authentik-nix.nixosModules.default
    inputs.agenix.nixosModules.default
  ];

  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    ports = {
      http = lib.mkOption {
        type = lib.types.int;
        default = 9000;
      };
      https = lib.mkOption {
        type = lib.types.int;
        default = 9443;
      };
    };
    secretsPath = lib.mkOption {
      type = lib.types.path;
    };
    blueprints = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.openssl
      pkgs.authentik
    ];

    users.groups.authentik = { };
    users.users.authentik = {
      isSystemUser = true;
      group = "authentik";
      extraGroups = [ "wheel" ];
    };

    # Agenix
    age.secrets.authentik-secret-key = {
      file = cfg.secretsPath + "/authentik-secret-key.age";
      owner = "root";
      group = "authentik";
      mode = "0640";
    };

    systemd.services.authentik-migrate.serviceConfig.DynamicUser = lib.mkForce false;
    systemd.services.authentik-worker.serviceConfig.DynamicUser = lib.mkForce false;
    systemd.services.authentik.serviceConfig.DynamicUser = lib.mkForce false;

    services.authentik = {
      enable = true;
      environmentFile = config.age.secrets.authentik-secret-key.path;
      settings = {
        disable_startup_analytics = true;

        listen = {
          listen_http = "0.0.0.0:${toString cfg.ports.http}";
          listen_https = "0.0.0.0:${toString cfg.ports.https}";
        };
      };
    };

    environment.etc = (
      builtins.listToAttrs
        (
          builtins.map (f: {
            name = "authentik/blueprints/custom/${builtins.baseNameOf f}";
            value = {
              source = "${f}";
            };
          }) cfg.blueprints
        )
    );

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "authentik" ];
      ensureUsers = [
        {
          name = "authentik";
          ensureDBOwnership = true;
        }
      ];
    };

    services.redis.servers.authentik = {
      enable = true;
      port = 6379;
    };

    networking.firewall.allowedTCPPorts = [
      cfg.ports.http
      cfg.ports.https
    ];
  };
}
