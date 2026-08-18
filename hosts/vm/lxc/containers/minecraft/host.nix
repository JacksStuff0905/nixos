{ config, ... }:
{
  host = {
    hostName = "ct-minecraft";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdRt4h+stPycNVRFphe0oc/4H2STP8Dw0aGSAY0ddMK";

    networking = {
      ip = "192.168.10.20/24";
      mac = "BC:24:11:1C:91:03";
    };

    isProduction = true;
    isServer = true;
  };
}
