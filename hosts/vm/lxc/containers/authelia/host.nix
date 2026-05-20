{ config, ... }:
{
  host = {
    hostName = "ct-authelia";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";

    networking.vpn.mesh = {
      enable = false;
      keyPath = ./secrets/vpn-mesh-key.age;
      pubKey = "";
      ip = "10.10.0.50";
      endpoint = " 95.175.23.220";
    };

    isProduction = true;
    isServer = true;
  };
}
