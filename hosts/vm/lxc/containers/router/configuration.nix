{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    # Services
    srv = {
      server = {
        router = {
          enable = true;

          firewall = {
            enable = true;
          };

          wan = {
            interface = "wan";

            dhcp = {
              client = true;
            };
          };

          lan = {
            bridge = {
              interfaces = [ "lan" ];
            };
          };
        };

        dhcp = {
          enable = true;
          interface = config.srv.server.router.lan.bridge.name;
        };
      };
    };
  };
}
