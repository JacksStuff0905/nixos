{ config, ... }:
{
  host = {
    hostName = "ct-authelia";

    isProduction = true;
    isServer = true;
  };
}
