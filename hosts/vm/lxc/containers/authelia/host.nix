{ config, ... }:
{
  host = {
    hostName = "ct-authelia";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";

    networking =
      let
        ip = "192.168.10.7";
        port = 9091;
        proto = "http";
      in
      {
        inherit ip;
        publicServices.auth = {
          inherit port proto;

          middleware = {
            enable = true;
            extraConfig = {
              forwardAuth = {
                address = "${proto}://${ip}:${toString port}/api/authz/forward-auth";
                trustForwardHeader = true;
                authResponseHeaders = [
                  "Remote-User"
                  "Remote-Groups"
                  "Remote-Email"
                  "Remote-Name"
                ];
              };
            };
          };
        };

        vpn.mesh = {
          enable = true;
          pubKey = "aJlonheVw4Ocd72iVo/wvKlNdKMwQ973fUNVNASi5wE=";
          ip = "10.10.0.50";
          endpoint = " 95.175.23.220";
        };
      };

    isProduction = true;
    isServer = true;
  };
}
