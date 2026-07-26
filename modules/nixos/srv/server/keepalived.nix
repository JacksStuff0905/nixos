{
  config,
  pkgs,
  lib,
  ...
}:
let
  name = "keepalived";
  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" =
    with lib;
    with lib.types;
    {
      enable = mkEnableOption "high availability";
      vrrpId = mkOption {
        type = int;
        description = "Unique virtual router Id";
      };
      priority = mkOption {
        type = int;
        default = if cfg.master.enable then 100 else 90;
      };
      master = {
        enable = mkEnableOption "master node";
      };
      interface = mkOption {
        type = str;
      };
      vip = mkOption {
        type = str;
      };
      script = mkOption {
        type = str;
      };
    };

  config = lib.mkIf cfg.enable {
    services.keepalived = {
      enable = true;
      openFirewall = true;

      extraGlobalDefs = ''
        enable_script_security
        use_symlink_paths true
      '';

      vrrpScripts = {
        "check_script" = {
          script = "${pkgs.writeShellScriptBin "vrrp_check_script" "${cfg.script}"}";
          interval = 5;
          weight = -50;
          fall = 3;
          rise = 2;
        };
      };

      vrrpInstances = {
        main = {
          state = if cfg.master.enable then "MASTER" else "BACKUP";
          virtualRouterId = cfg.vrrpId;
          priority = cfg.priority;
          interface = cfg.interface;

          virtualIps = [
            { addr = cfg.vip; }
          ];

          trackScripts = [ "check_script" ];

          extraConfig = ''
            advert_int 1
            authentication {
              auth_type PASS
              auth_pass VRRP_CONN_${toString cfg.vrrpId}
            }
          '';
        };
      };
    };
  };
}
