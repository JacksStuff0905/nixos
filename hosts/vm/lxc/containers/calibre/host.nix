{ config, ... }:
{
  host = {
    hostName = "ct-calibre";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjv08OFWbD5qQ+YajLHSxfgyYEP1/yfnuUG8xxslbWz";

    networking = {
      ip = "192.168.10.12";
      publicServices.books = {
        proto = "http";
        port = 8083;

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
