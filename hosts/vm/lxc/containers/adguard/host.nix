{ config, ... }:
{
  host = {
    hostName = "ct-adguard";

    isProduction = true;
    isServer = true;
  };
}
