{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.srv.lamp-test;
in
{
  options.srv.lamp-test = {
    enable = lib.mkEnableOption "xampp like lamp setup";
    documentRoot = lib.mkOption {
      type = lib.types.str;
    };
    user = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.httpd.enable = true;
    services.httpd.adminAddr = "webmaster@example.org";
    services.httpd.enablePHP = true;

    services.httpd.virtualHosts."localhost" = {
      documentRoot = "${cfg.documentRoot}";
    };

    services.mysql.enable = true;
    services.mysql.package = pkgs.mariadb;
    services.mysql.initialScript = pkgs.writeText "init.sql" ''
      SET PASSWORD FOR root@localhost="";
      FLUSH PRIVILAGES;
    '';

    # hacky way to create our directory structure and index page... don't actually use this
    systemd.tmpfiles.rules = [
      "d ${cfg.documentRoot} - ${cfg.user}"
      "Z ${cfg.documentRoot} - ${cfg.user}"
      "f ${cfg.documentRoot}/index.php - - - - <?php phpinfo();"
    ];
  };
}
