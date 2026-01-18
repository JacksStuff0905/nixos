{config, lib, pkgs, ...}:
let
  cfg = config.srv.ssh;
in
{
  options.srv.ssh = {
    enable = lib.mkEnableOption "Enable openssh module";
    ports = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [22];
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = cfg.ports;
    };
    
    networking.firewall.allowedTCPPorts = cfg.ports;
  };
}
