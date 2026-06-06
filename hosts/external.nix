{ pkgs }:
let
  lib = pkgs.lib;
in
{
  truenas-vm = {
    networking = {
      ip = "192.168.10.6";
      publicServices.nas = {
        proto = "http";
        port = 80;

        middlewares = [ "auth.srv.lan" ];

        access = [
          {
            policy = "one_factor";
            subject = "group:netadmins";
          }
        ];
      };
    };

    isProduction = true;
    isServer = true;
  };

  proxmox = {
    networking = {
      ip = "192.168.8.11";
      publicServices.pve = {
        proto = "https";
        port = 8006;

        middlewares = [ "auth.srv.lan" ];

        access = [
          {
            policy = "one_factor";
            subject = "group:netadmins";
          }
        ];
      };
    };

    isProduction = true;
    isServer = true;
  };

  opnsense-vm = {
    networking = {
      ip = "192.168.10.1";
      publicServices.router = {
        proto = "https";
        port = 443;

        middlewares = [ "auth.srv.lan" ];

        access = [
          {
            policy = "one_factor";
            subject = "group:netadmins";
          }
        ];
      };
    };

    isProduction = true;
    isServer = true;
  };
}
