{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "filebrowser";

  cfg = config.virtualization.docker.stacks."${name}";

  port = 30051;

  mkNFSMount =
    { target, share }:
    let
      matches = builtins.match "([^:]+):(.*)" share;
    in
    [
      "--mount"
      (builtins.concatStringsSep "," [
        "type=volume"
        "target=${target}" # Where it appears inside the container
        "volume-driver=local"
        "volume-opt=type=nfs"
        "\"volume-opt=o=addr=${builtins.elemAt matches 0},rw,nfsvers=4\"" # IP and Options
        "volume-opt=device=:${builtins.elemAt matches 1}" # Path on the NAS
      ])
    ];
in
{
  options.virtualization.docker.stacks."${name}" = {
    enable = lib.mkEnableOption "Enable ${name} docker stack";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nfs-utils ];
    
    networking.firewall.allowedTCPPorts = [
      port
    ];

    virtualisation.oci-containers.containers = {
      filebrowser = {
        image = "filebrowser/filebrowser:latest";
        ports = [
          "${toString port}:80"
        ];
        environment = {
          PUID = "3002";
          PGID = "3003";
        };
        extraOptions = lib.mkMerge [
          (mkNFSMount {
            target = "/srv/VM-Data/Docker";
            share = "192.168.10.6:/mnt/Main4TB/VM-Data/Docker";
          })
          (mkNFSMount {
            target = "/srv/VM-Data/Proxmox";
            share = "192.168.10.6:/mnt/Main4TB/VM-Data/Proxmox";
          })
        ];
        volumes = [
          "/data/stacks/remote/${name}/db/:/db/"
          "/data/stacks/remote/${name}/config/:/config/"
        ];
        cmd = [ 
          "--database" "/db/filebrowser.db" 
          "--root" "/srv"
        ];
      };
    };
  };
}
