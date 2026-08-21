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
    srv.server = {
      wireguard = {
        enable = true;
        interface = "eth0";
        ip = "192.168.100.1/24";

        publicKey = "CPhvcGgH23lMyzzmfiOj+UGfa9MfCPYYxgrZcuylDjQ=";

        privateKeySecret = ./secrets/wireguard-private-key.age;
        peers = [
          {
            # Phone
            publicKey = "8kKcHcDVgOtZ1JqcvguP3dRlIVCjHfrjsXvcUtiQ0TI=";
            allowedIPs = [
              "192.168.100.15/32"
            ];
          }
          {
            # Laptop
            publicKey = "KcCv3S9PBVQABekikcr4uDVBuUtZ8T5pYU+DpSywYnE=";
            allowedIPs = [
              "192.168.100.16/32"
            ];
          }
          {
            # Laptop 2
            publicKey = "BjYQiwSZkeCU5kAaDYCrdJU5dwizpNvNBvofpQEl+hc=";
            allowedIPs = [
              "192.168.100.17/32"
            ];
          }
        ];
      };
    };

    networking.firewall.enable = true;

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
