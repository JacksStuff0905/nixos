{ config, ... }:
{
  host = {
    hostName = "vm-router";

    isProduction = true;
    isServer = true;
  };
}
