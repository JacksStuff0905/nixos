{ config, ... }:
{
  host = {
    hostName = "ct-wireguard";

    isProduction = true;
    isServer = true;
  };
}
