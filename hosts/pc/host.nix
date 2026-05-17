{ config, ... }:
{
  host = {
    hostName = "jacek-pc";

    username = "jacek";

    #userPubKey = "age1jhxld58nuudn0cj6k62plh7szzt8nj0zah5fsjmq265m6l88tudsahwsf8";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJtaLUPMHMbSu/b7F1FrHbyqq2B0SfFCrBLo1pTxXFq";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
