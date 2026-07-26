{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "netboot";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "${name}";
  };

  config = lib.mkIf cfg.enable {
    services.pixiecore = {
      enable = true;
      openFirewall = true;
      dhcpNoBind = true;
      kernel = "https://boot.netboot.xyz";
    };
  };
}
