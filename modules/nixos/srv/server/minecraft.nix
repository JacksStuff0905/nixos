# !!! WIP !!!

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  name = "minecraft";

  cfg = config.srv.server."${name}";

  types = {
    server = types.submodule (
      { name, ... }:
      {
        options = {
        };
      }
    );
  };
in
{
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];

  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "${name}";
    servers = lib.mkOption {
      type = lib.types.attrsOf types.server;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

    environment.systemPackages = with pkgs; [ tmux ];

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;

      servers = {
        test-server = {
          enable = false;
          jvmOpts = "-Xmx4G -Xms2G";
          package = pkgs.vanillaServers.vanilla-26_2;
          serverProperties = {
            motd = "test server";
            online-mode = false;
            server-port = 25565;
            simulation-distance = 10;
            view-distance = 12;
          };
          whitelist = { };
        };

        new-server = {
          enable = true;
          jvmOpts = "-Xmx4G -Xms2G";
          package = pkgs.fabricServers.fabric-26_2.override { jre_headless = pkgs.openjdk25_headless; };
          serverProperties = {
            motd = "new server";
            online-mode = false;
            server-port = 25565;
            simulation-distance = 10;
            view-distance = 12;
          };
          symlinks = {
            "mods" = pkgs.linkFarmFromDrvs "mods" (
              builtins.attrValues {
                ServerSideHorror = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/RJ4U0qmn/versions/9ryFHe7y/serversidehorror-26.2-fabric-4.2.jar";
                  sha512 = "sha512-LJdjG4MkbIn3J/AXnKzGQQmXxyg0PowbRfa/oUR9HAjw1PkU7xulxygz+dt4/ky3/P/uwIhuIIpHI9Q6ycPOBw==";
                };

                Deimos = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/WQaxNzFg/versions/zRp7vgbN/deimos-26.2-fabric-2.7.jar";
                  sha256 = "sha256-0X8v7LA3Xjw7TQQh3Oj53Q0wc5rNYaWy2pcCiqlCy+8=";
                };

                FabricAPI = pkgs.fetchurl {
                  url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/vmQp7ixA/fabric-api-0.157.0%2B26.2.jar";
                  sha256 = "sha256-rLfckKBDBRnElUgHTT+/b9gdEwY/CPCvNEsqawikJiA=";
                };
              }
            );
          };
          whitelist = { };
        };
      };
    };
  };
}
