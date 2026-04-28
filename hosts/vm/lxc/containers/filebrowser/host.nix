{ config, ... }:
{
  host = {
    hostName = "ct-filebrowser";

    sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdkmeR53wnrKjOZsDK1Uj51LPceVWXqLv0bW9WpH89O";

    isProduction = true;
    isServer = true;
  };
}
