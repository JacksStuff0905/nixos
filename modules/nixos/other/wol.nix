{
  pkgs,
  config,
  lib,
  ...
}:

let
  name = "wol";
  cfg = config.other.${name};
in
{
  options.other.${name} = {
    enable = lib.mkEnableOption "${name}";
    interface = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      interfaces = {
        "${cfg.interface}" = {
          wakeOnLan.enable = true;
        };
      };
      firewall = {
        allowedUDPPorts = [ 9 ];
      };
    };
  };
}
