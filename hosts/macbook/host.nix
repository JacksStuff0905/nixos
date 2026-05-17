{ config, ... }:
{
  host = {
    hostName = "jacek-macbook";

    username = "jacek";

    userPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/pGueja9l7ovfuotcmfgtrwnMCu5RL4i2JIewjzJhp";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbUmyaaN+Q1gCkJVVVdIQro+cPqueFF+Dx4qcNTP0zy";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
