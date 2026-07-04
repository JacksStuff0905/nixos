{ config, ... }:
{
  host = {
    hostName = "ct-adguard2";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYZbo/H8gJY4/PzSHVcuw1PYnOh1Nlzrw1Jjn8v9ixP";

    networking = {
      ip = "192.168.16.5/24";
      mac = "BC:24:11:5F:2B:DD";
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
