{ config, ... }:
{
  host = {
    hostName = "jacek-macbook";

    username = "jacek";

    sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbUmyaaN+Q1gCkJVVVdIQro+cPqueFF+Dx4qcNTP0zy";

    isProduction = true;
    isDesktop = true;
  };
}
