{ config, util, ... }:
{
  host = {
    hostName = "ct-authelia";

    hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";

    networking =
      let
        ip = "192.168.10.7/24";
        port = 9091;
        proto = "http";
      in
      {
        inherit ip;
        mac = "BC:24:11:60:CF:10";
        publicServices = {
          ldap = {
            proto = "tcp";
            port = 3890;
          };

          auth = {
            inherit port proto;

            middleware = {
              enable = true;
              extraConfig = {
                forwardAuth = {
                  address = "${proto}://${(util.tools.ip-nix.splitIp ip).ip}:${toString port}/api/authz/forward-auth";
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

        };

        vpn.mesh = {
          enable = true;
          pubKey = "aJlonheVw4Ocd72iVo/wvKlNdKMwQ973fUNVNASi5wE=";
          ip = "10.10.0.50";
        };
      };

    isProduction = true;
    isServer = true;
  };
}
