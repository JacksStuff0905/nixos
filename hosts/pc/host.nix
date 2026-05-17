{ config, ... }:
{
  host = {
    hostName = "jacek-pc";

    username = "jacek";

    userPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFS1jwKvufBe2kP+ZuSZhXrYA29H9XdAsklrxTw6hw3B";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJtaLUPMHMbSu/b7F1FrHbyqq2B0SfFCrBLo1pTxXFq";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
