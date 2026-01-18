{config, lib, ...}:
let
  name = "nginx-proxy-manager";

  cfg = config.virtualization.docker.stacks."${name}";
in
{
  options.virtualization.docker.stacks."${name}" = {
    enable = lib.mkEnableOption "Enable ${name} docker stack";
  };

  
  config.virtualisation.oci-containers.containers = lib.mkIf cfg.enable {
    nginx-proxy-manager = {
      image = "jc21/nginx-proxy-manager:latest";
      ports = [
        "80:80" # Public HTTP Port
        "443:443" # Public HTTPS Port
        "81:81" # Admin Web Port
      ];
      environment = { 
        TZ = "Poland/Warsaw";
        PUID = "3002";
        PGID = "3004";
      };
      volumes = [
        "/data/stacks/remote/${name}/data:/data"
        "/data/stacks/remote/${name}/letsencrypt:/etc/letsencrypt"
      ];
    };
  };
}
