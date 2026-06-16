{ pkgs }:
let
  lib = pkgs.lib;

  publicService =
    with lib;
    with types;
    submodule {
      options = {
        port = mkOption {
          type = int;
        };

        proto = mkOption {
          type = enum [
            "http"
            "https"
            "tcp"
            "tcp/udp"
          ];
        };

        middleware = {
          enable = mkEnableOption "middleware for this service";
          extraConfig = mkOption {
            type = attrs;
            default = { };
          };
        };

        middlewares = mkOption {
          type = listOf str;
          default = [ ];
        };

        access = mkOption {
          type = listOf (submodule {
            options = {
              policy = mkOption {
                type = enum [
                  "bypass"
                  "one_factor"
                  "two_factor"
                  "deny"
                ];
              };

              subject = mkOption {
                type = nullOr (either str (listOf (either str (listOf str))));
                default = null;
              };
            };
          });
          default = [ ];
        };
      };
    };

  host =
    config:
    with lib;
    types.submodule {
      options = with lib.types; {
        hostName = mkOption {
          type = str;
          description = "The hostname of the host";
        };
        networking = {
          ip = mkOption {
            type = nullOr str;
            default = null;
          };
          domain = mkOption {
            type = nullOr str;
            description = "The domain of the host";
            default = "srv.lan";
          };
          publicServices = mkOption {
            type = attrsOf publicService;
            default = { };
          };
          vpn = {
            mesh = {
              enable = mkEnableOption "mesh vpn";
              pubKey = mkOption {
                type = str;
                description = "The mesh vpn public key";
              };
              keyPath = mkOption {
                type = path;
                description = "The path to the age encrypted private key file";
                default = ./secrets/vpn-mesh/vpn-mesh-key.age;
              };
              ip = mkOption {
                type = str;
                description = "The mesh vpn ip address of this host";
              };
              name = mkOption {
                type = str;
                description = "The mesh vpn dns name of this host (hostname by default)";
                default = "${config.host.hostName}";
              };
              endpoint = mkOption {
                type = nullOr str;
                description = "The mesh vpn endpoint of this host (or null)";
                default = null;
              };
              ports = {
                wireguard = mkOption {
                  type = int;
                  default = 51820;
                };
                gossip = mkOption {
                  type = int;
                  default = 7946;
                };
              };
              persistentKeepalive = mkOption {
                type = int;
                default = 25;
              };
              extraAllowedIPs = mkOption {
                type = listOf str;
                default = [ ];
              };
            };
          };

          extraConfig = mkOption {
            default = { };
            type = attrsOf anything;
            description = "An attribute set of networking information";
          };
        };
        hostPubKey = mkOption {
          type = nullOr str;
          description = "The public ssh key of the host";
          default = null;
        };

        user = {
          name = mkOption {
            type = str;
            description = "The username of the host";
            default = "root";
          };
          pubKey = mkOption {
            type = nullOr str;
            description = "The public ssh (converted to age - `ssh-to-age`) key of the user";
            default = null;
          };
          keyPath = mkOption {
            type = nullOr str;
            description = "The private ssh key path of the user";
            default = null;
          };
          fullName = mkOption {
            type = str;
            description = "The full name of the user";
          };
          home = mkOption {
            type = str;
            description = "The home directory of the user";
            default =
              let
                user = config.host.user.name;
              in
              if pkgs.stdenv.isLinux then
                (if user == "root" then "/root" else "/home/${user}")
              else
                "/Users/${user}";
          };
          email = mkOption {
            type = attrsOf str;
            description = "The email of the user";
          };
        };

        # Configuration Settings
        isDev = mkOption {
          type = bool;
          default = false;
          description = "Used to indicate a developer host (used to write secrets etc.)";
        };
        isMinimal = mkOption {
          type = bool;
          default = false;
          description = "Used to indicate a minimal host";
        };
        isProduction = mkOption {
          type = bool;
          default = false;
          description = "Used to indicate a production host";
        };
        isTesting = mkOption {
          type = bool;
          default = false;
          description = "Used to indicate a testing host";
        };
        isServer = mkOption {
          type = bool;
          default = false;
          description = "Used to indicate a server host";
        };
        isDesktop = mkOption {
          type = bool;
          default = false;
          description = "Used to indicate a desktop host";
        };
      };
    };
in
{
  inherit host publicService;
}
