{
  description = "Main NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-nix.url = "github:JacksStuff0905/nvim-nix";
    godot-nix.url = "github:JacksStuff0905/godot-nix";

    authentik-nix.url = "github:nix-community/authentik-nix";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      util = {
        get-import-dir =
          dir: ignore:
          import ./util/get-import-dir.nix {
            lib = pkgs.lib;
            dir = dir;
            ignore = ignore;
            self = import ./util/get-import-dir.nix;
          };
        get-files-dir =
          dir: ignore:
          import ./util/get-files-dir.nix {
            lib = pkgs.lib;
            dir = dir;
            ignore = ignore;
            self = import ./util/get-files-dir.nix;
          };
      };
    in
    {
      nixosConfigurations = ({
        macbook = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit util;
            inherit system;
          };

          modules = [
            ./hosts/macbook/configuration.nix
            inputs.home-manager.nixosModules.default
            {
              home-manager.extraSpecialArgs = {
                inherit util;
                inherit system;
              };
            }
            inputs.nvim-nix.nixosModules.default
          ];
        };

        vm-docker = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit util;
            inherit system;
          };

          modules = [
            ./hosts/vm/docker/configuration.nix
            inputs.home-manager.nixosModules.default
            {
              home-manager.extraSpecialArgs = {
                inherit util;
                inherit system;
              };
            }
            inputs.nvim-nix.nixosModules.default
          ];
        };
      })

      # LXCs
      // (import ./hosts/vm/lxc/containers/default.nix {
        lib = pkgs.lib;
        inherit
          util
          inputs
          system
          nixpkgs
          ;
      });
    };
}
