{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "nginx";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    virtualHosts = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;

      virtualHosts = cfg.virtualHosts;
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
