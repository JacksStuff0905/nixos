{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.srv.printing;
in
{
  options.srv.printing = {
    enable = lib.mkEnableOption "Enable printing module";
    autodetect = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    drivers = {
      hp = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = [
        (lib.mkIf cfg.drivers.hp pkgs.hplip)
        (lib.mkIf cfg.autodetect pkgs.gutenprint)
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.printers = lib.mkIf cfg.autodetect {
      ensurePrinters = [ ];
    };
  };
}
