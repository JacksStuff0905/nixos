{ config, ... }:
{
  host = {
    hostName = "ct-jellyfin";

    isProduction = true;
    isServer = true;
  };
}
