{ config, ... }:
{
  host = {
    hostName = "ct-web";

    isProduction = true;
    isServer = true;
  };
}
