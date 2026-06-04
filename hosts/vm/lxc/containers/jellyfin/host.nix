{ config, ... }:
{
  host = {
    hostName = "ct-jellyfin";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqJIvuk443GYXBHyvxuYAWNm4sahXMpMaZqvpz89fDN";

    networking = {
      ip = "192.168.10.127";
      publicServices.films = {
        proto = "http";
        port = 80;
      };
    };

    isProduction = true;
    isServer = true;
  };
}
