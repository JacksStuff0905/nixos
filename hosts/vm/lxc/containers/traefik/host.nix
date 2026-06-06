{ config, ... }:
{
  host = {
    hostName = "ct-traefik";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUsJvfpWY36UgQrR1/6xKyI1bByBfc2Ut553fHmpH9W";

    networking = {
      ip = "192.168.10.9";

      publicServices.proxy = {
        middlewares = [ "auth.srv.lan" ];
        proto = "http";
        port = 8080;
        access = [
          {
            policy = "one_factor";
            subject = [ "group:netadmins" ];
          }
        ];
      };
    };

    isProduction = true;
    isServer = true;
  };
}
