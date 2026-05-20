{ config, ... }:
{
  host = {
    hostName = "ct-filebrowser";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdkmeR53wnrKjOZsDK1Uj51LPceVWXqLv0bW9WpH89O";

    networking.vpn.mesh = {
      enable = false;
      keyPath = ./secrets/vpn-mesh-key.age;
      pubKey = "";
      ip = "10.10.0.40";
      endpoint = " 95.175.23.220";
    };

    isProduction = true;
    isServer = true;
  };
}
