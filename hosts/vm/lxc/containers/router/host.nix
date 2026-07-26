{ config, ... }:
{
  host = {
    hostName = "ct-router";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTPwX5e+8rEbbvMjHpMh7QCcT5Xy4K3KnI/SrpNMvcS";
    networking = {
      ip = "192.168.10.1/24";
      mac = "BC:24:11:A2:49:9D";
    };

    isProduction = true;
    isServer = true;
  };
}
