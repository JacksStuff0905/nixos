{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.de.gnome;
in
{
  options.de.gnome = {
    enable = lib.mkEnableOption "Enable gnome module";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.gnome.enable = true;

    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];
      config = {
        common.default = [ "gnome" ];
      };
    };
  };
}
