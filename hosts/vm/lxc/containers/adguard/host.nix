{ config, ... }:
{
  host = {
    hostName = "ct-adguard";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZm2hVrbbTMv7yDYw6Yohh1cCGCiRv7ObVWvtFHzHDQ";

    networking = {
      ip = "192.168.10.5";
      publicServices.dns = {
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
}
