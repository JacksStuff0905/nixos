{ config, ... }:
{
  host = {
    hostName = "ct-traefik";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUsJvfpWY36UgQrR1/6xKyI1bByBfc2Ut553fHmpH9W";

    isProduction = true;
    isServer = true;
  };
}
