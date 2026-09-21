{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.other.apps.steam;
in
{
  options.other.apps.steam = {
    enable = lib.mkEnableOption "Enable steam module";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      gamescope = {
        enable = true;
        #capSysNice = true;
      };
      steam = {
        enable = true;
        gamescopeSession.enable = true;
      };
    };

    # Temp fix
    services.seatd.enable = true;

    users.users."${config.host.user.name}".extraGroups = [
      "video"
      "input"
      "audio"
    ];
  };
}
