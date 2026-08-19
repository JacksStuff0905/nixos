{ config, ... }:
{
  host = {
    hostName = "jacek-framework";

    user = {
      name = "jacek";

      pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1SjAsAsv1ZHtARTo8GHqIkod7kUiHrzK/7BZ1TpreX";
    };

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZEwA5J0YwvzP6IqDExxx/V0KQCvRJ+KurGJeOChJBb";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
