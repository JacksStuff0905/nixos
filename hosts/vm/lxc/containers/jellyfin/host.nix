{ config, ... }:
{
  host = {
    hostName = "ct-jellyfin";

    hostPubKey = "";

    isProduction = true;
    isServer = true;
  };
}
