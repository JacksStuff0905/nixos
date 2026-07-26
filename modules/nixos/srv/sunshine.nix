{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.srv.sunshine;
in
{
  options.srv.sunshine = {
    enable = lib.mkEnableOption "sunshine";
    user = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    srv.sunshine.user = lib.mkDefault config.host.user.name;
    users.users."${cfg.user}".extraGroups = [ "uinput" ];
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
