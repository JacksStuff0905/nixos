{ config, ... }:
{
  host = {
    hostName = "jacek-macbook";

    user = {
      name = "jacek";

      pubKey = "age1x95fs8qjfs9w70vzuggc50v9tkztlvg77gm9y295yv32yamplf5qp2fzx9";
    };

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbUmyaaN+Q1gCkJVVVdIQro+cPqueFF+Dx4qcNTP0zy";

    isDev = true;
    isProduction = true;
    isDesktop = true;
  };
}
