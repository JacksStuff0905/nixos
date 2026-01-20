{ config, lib, ... }:
let
  name = "calibre";

  cfg = config.virtualization.docker.stacks."${name}";

  web-port = 8083;
  admin-port-desktop-rp = 8080;
  admin-port-desktop-https = 8181;
  admin-port-webserver = 8081;
in
{
  options.virtualization.docker.stacks."${name}" = {
    enable = lib.mkEnableOption "Enable ${name} docker stack";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      web-port
      admin-port-desktop-rp
      admin-port-desktop-https
      admin-port-webserver
    ];

    virtualisation.oci-containers.containers = {
      calibre-admin = {
        image = "lscr.io/linuxserver/calibre:latest";

        autoStart = false;

        environment = {
          PUID = "3002";
          PGID = "3003";
          TZ = "Poland/Warsaw";
        };
        volumes = [
          "/data/stacks/remote/${name}/config/calibre-admin:/config"
          "/data/stacks/remote/${name}/books:/books"
        ];
        ports = [
          "${toString admin-port-desktop-rp}:8080"
          "${toString admin-port-desktop-https}:8181"
          "${toString admin-port-webserver}:8081"
        ];
      };

      calibre-web = {
        image = "lscr.io/linuxserver/calibre-web:latest";
        environment = {
          PUID = "3002";
          PGID = "3003";
          TZ = "Europe/Warsaw";
          DOCKER_MODS = "linuxserver/mods:universal-calibre";
        };
        volumes = [
          "/data/stacks/remote/${name}/config/calibre-web:/config"
          "/data/stacks/remote/${name}/books:/books"
        ];
        ports = [
          "${toString web-port}:8083"
        ];
      };
    };
  };
}
