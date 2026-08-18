{ config, ... }:
{
  host = {
    hostName = "jacek-framework";

    user = {
      name = "jacek";

      pubKey = "";
    };

    hostPubKey = "";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
