{ config, lib, pkgs, ... }:
let
  cfg = config.other.xdg-portal;
in
{
  options.other.xdg-portal = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
