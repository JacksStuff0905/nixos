{
  config,
  lib,
  pkgs,
  util,
  ...
}:
let
  name = "wireguard";

  cfg = config.srv.server."${name}";
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "${name}";

    interface = lib.mkOption {
      type = lib.types.str;
    };

    ip = lib.mkOption {
      type = lib.types.str;
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = { };
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
    };

    privateKeySecret = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "eth0";
      internalInterfaces = [ "wg0" ];
    };
    # Open ports in the firewall
    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [
        53
        51834
      ];
      trustedInterfaces = [ "wg0" ];
    };

    age.secrets = {
      wireguard-private-key = {
        rekeyFile = cfg.privateKeySecret;
        mode = "0666";
      };
    };

    environment.systemPackages = [
      pkgs.wireguard-tools
      pkgs.qrencode
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.wg-quick.interfaces =
      let
        net = util.tools.ip-nix.getSubnet cfg.ip;
      in
      {
        # "wg0" is the network interface name. You can name the interface arbitrarily.
        wg0 = {
          # Determines the IP/IPv6 address and subnet of the client's end of the tunnel interface
          address = [
            cfg.ip
          ];
          # The port that WireGuard listens to - recommended that this be changed from default
          listenPort = 51834;
          # Path to the server's private key
          privateKeyFile = config.age.secrets.wireguard-private-key.path;

          # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
          postUp = ''
            ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${cfg.ip} -o ${cfg.interface} -j MASQUERADE
            ${pkgs.iptables}/bin/iptables -A FORWARD -o wg0 -j ACCEPT
          '';

          # Undo the above
          preDown = ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${cfg.ip} -o ${cfg.interface} -j MASQUERADE
            ${pkgs.iptables}/bin/iptables -D FORWARD -o wg0 -j ACCEPT
          '';

          peers = cfg.peers;
        };
      };
  };
}
