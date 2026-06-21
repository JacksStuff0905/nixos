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
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${config.host.user.name}" ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    users.users = builtins.listToAttrs (
      builtins.map (u: {
        name = u;
        value = {
          extraGroups = [
            "scanner"
            "lp"
          ];
        };
      }) cfg.users
    );
  };
}
