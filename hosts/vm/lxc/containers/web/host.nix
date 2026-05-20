{ config, ... }:
{
  host = {
    hostName = "ct-web";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHV8OQtXmKYXvME1bhoSf6hJT89BOwNxfBfmGif2BuUX";

    isProduction = true;
    isServer = true;
  };
}
