{ config, ... }:
{
  host = {
    hostName = "ct-authelia";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";

    isProduction = true;
    isServer = true;
  };
}
