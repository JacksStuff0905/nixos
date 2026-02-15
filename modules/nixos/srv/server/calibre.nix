{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "calibre";

  cfg = config.srv.server."${name}";
  web-port = 8083;
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    library = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    authentik = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      web-port
    ];

    environment.systemPackages = [
      pkgs.calibre
    ];

    services.calibre-web = {
      enable = true;
      listen.ip = "0.0.0.0";
      listen.port = web-port;
      options = {
        calibreLibrary = cfg.library;
        enableBookConversion = true;
        enableBookUploading = true;
        reverseProxyAuth = lib.mkIf cfg.authentik {
          enable = true;
          header = "X-authentik-username";
        };
      };
    };
  };
}
