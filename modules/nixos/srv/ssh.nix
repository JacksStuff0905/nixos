{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.srv.ssh;
in
{
  options.srv.ssh = {
    server = {
      enable = lib.mkEnableOption "Enable openssh module";
      enableRoot = lib.mkEnableOption "Enable root";
      ports = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ 22 ];
      };
    };
    agent = {
      enable = lib.mkEnableOption "ssh-agent";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      services.openssh = {
        enable = true;
        ports = cfg.server.ports;
        settings.PermitRootLogin = if cfg.server.enableRoot then "yes" else "no";
      };

      networking.firewall.allowedTCPPorts = cfg.server.ports;
    })
    (lib.mkIf cfg.agent.enable {
      programs.ssh.startAgent = true;
    })
  ];
}
