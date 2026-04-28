{ config, ... }:
{
  host = {
    hostName = "jacek-pc";

    username = "jacek";

    sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJtaLUPMHMbSu/b7F1FrHbyqq2B0SfFCrBLo1pTxXFq";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
