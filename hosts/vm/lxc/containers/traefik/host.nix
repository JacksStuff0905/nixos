{ config, ... }:
{
  host = {
    hostName = "ct-traefik";

    isProduction = true;
    isServer = true;
  };
}
