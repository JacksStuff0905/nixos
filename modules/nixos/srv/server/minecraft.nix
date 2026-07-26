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

    services.minecraft-servers = {
      enable = true;
      eula = true;

      servers = {
        test-server = {
          enable = true;
          serverProperties = { };
          whitelist = { };
        };
      };
    };
  };
}
