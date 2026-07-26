{ config, ... }:
{
  host = {
    hostName = "ct-wireguard";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMq8vrAxeoZ9S9x4k1JYlUnXqrGIcn8MesF/IRqR8Q2V";

    networking = {
      ip = "192.168.10.10/24";
      mac = "BC:24:11:11:E1:E1";
    };

    isProduction = true;
    isServer = true;
  };
}
