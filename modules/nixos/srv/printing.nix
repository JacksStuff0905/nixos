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
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = [
        #(lib.mkIf cfg.drivers.hp pkgs.hplip)
        #pkgs.gutenprint
        pkgs.cups-filters
        pkgs.cups-browsed
      ];
      browsing = true;
    };

    services.avahi = {
      enable = true;
      nssmdns = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    #hardware.sane.enable = true;

    hardware.printers = {
      ensurePrinters = [ ];
    };
  };
}
