{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "jellyfin";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true; # We use reverse proxy
    };

    # Hardware acceleration (optional)
    hardware.opengl = {
      enable = true;
    };

    # Add jellyfin user to video/render groups for HW accel
    users.users.jellyfin.extraGroups = [
      "video"
      "render"
    ];
  };
}
