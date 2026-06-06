{ config, ... }:
{
  host = {
    hostName = "ct-web";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHV8OQtXmKYXvME1bhoSf6hJT89BOwNxfBfmGif2BuUX";

    networking = {
      ip = "192.168.10.15";
      publicServices.home = {
        proto = "http";
        port = 80;

        middlewares = [ "auth.srv.lan" ];

        access = [
          {
            policy = "one_factor";
            subject = "group:netusers";
          }
        ];
      };
    };

    isProduction = true;
    isServer = true;
  };
}
