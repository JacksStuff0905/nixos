{ config, lib, ... }:
let
  name = "calibre";

  cfg = config.virtualization.docker.stacks."${name}";
in
{
  options.virtualization.docker.stacks."${name}" = {
    enable = lib.mkEnableOption "Enable ${name} docker stack";
  };

  config.virtualisation.oci-containers.containers = lib.mkIf cfg.enable {
    calibre-admin = {
      image = "lscr.io/linuxserver/calibre:latest";

      autoStart = false;

      environment = {
        PUID = "3002";
        PGID = "3004";
        TZ = "Poland/Warsaw";
      };
      volumes = [
        "/data/stacks/remote/${name}/config/calibre-admin:/config"
        "/data/stacks/remote/${name}/books:/books"
      ];
      ports = [
        "8080:8080"
        "8181:8181"
        "8081:8081"
      ];
    };

    calibre-web = {
      image = "lscr.io/linuxserver/calibre-web:latest";
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Warsaw";
        DOCKER_MODS = "linuxserver/mods:universal-calibre";
      };
      volumes = [
        "/data/stacks/remote/${name}/config/calibre-web:/config"
        "/data/stacks/remote/${name}/books:/books"
      ];
      ports = [
        "8083:8083"
      ];
    };
  };
}
