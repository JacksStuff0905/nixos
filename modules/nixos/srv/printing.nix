{config, lib, pkgs, ...}:
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
    };
    
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
