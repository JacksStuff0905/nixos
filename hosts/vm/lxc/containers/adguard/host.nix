{ config, ... }:
{
  host = {
    hostName = "ct-adguard";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZm2hVrbbTMv7yDYw6Yohh1cCGCiRv7ObVWvtFHzHDQ";

    isProduction = true;
    isServer = true;
  };
}
