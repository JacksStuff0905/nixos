{ config, ... }:
{
  host = {
    hostName = "ct-calibre";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjv08OFWbD5qQ+YajLHSxfgyYEP1/yfnuUG8xxslbWz";

    isProduction = true;
    isServer = true;
  };
}
