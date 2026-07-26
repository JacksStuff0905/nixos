{ config, ... }:
{
  host = {
    hostName = "ct-netboot";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/d8xNYPj4VoKZa+ZOOFzWqZQUQZkK8PEBCZAL9aN35";

    isProduction = true;
    isServer = true;
  };
}
