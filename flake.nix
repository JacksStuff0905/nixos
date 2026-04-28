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

    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
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

      lib = nixpkgs.lib;

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

      hostSpec = (
        { config, lib, ... }:
        {
          options.host = lib.mkOption {
            description = "This host's specification";
            type =
              with lib;
              types.submodule {
                options = with lib.types; {
                  username = mkOption {
                    type = str;
                    description = "The username of the host";
                    default = "root";
                  };
                  hostName = mkOption {
                    type = str;
                    description = "The hostname of the host";
                  };
                  email = mkOption {
                    type = attrsOf str;
                    description = "The email of the user";
                  };
                  networking = mkOption {
                    default = { };
                    type = attrsOf anything;
                    description = "An attribute set of networking information";
                  };
                  domain = mkOption {
                    type = str;
                    description = "The domain of the host";
                  };
                  userFullName = mkOption {
                    type = str;
                    description = "The full name of the user";
                  };
                  home = mkOption {
                    type = str;
                    description = "The home directory of the user";
                    default =
                      let
                        user = config.host.username;
                      in
                      if pkgs.stdenv.isLinux then
                        (if user == "root" then "/root" else "/home/${user}")
                      else
                        "/Users/${user}";
                  };
                  sshPubKey = mkOption {
                    type = nullOr str;
                    description = "The public ssh key of the host";
                    default = null;
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

          };
        }
      );

      agenixModule = (
        { config, inputs, ... }:
        {
          imports = [
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
          ];

          age.rekey = lib.mkMerge [
            (lib.mkIf (config.host ? sshPubKey && config.host.sshPubKey != null) {
              hostPubkey = config.host.sshPubKey;

              masterIdentities = lib.mkIf (config ? host && config.host ? home && config.host.isDev) [
                "${config.host.home}/.ssh/id_ed25519"
              ];
            })
            {
              storageMode = "local";

              localStorageDir = ./. + "/secrets/rekeyed/${config.host.hostName}";
            }
          ];
        }
      );

      hosts = lib.mapAttrs (name: cfg: cfg.config) self.nixosConfigurations;
    in
    {
      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations;
        darwinConfigurations = self.darwinConfigurations or { };
        # Example for colmena:
        # nixosConfigurations = ((colmena.lib.makeHive self.colmena).introspect (x: x)).nodes;
      };

      nixosConfigurations = ({
        macbook = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              util
              system
              hosts
              ;
          };

          modules = [
            ./hosts/macbook/configuration.nix
            inputs.home-manager.nixosModules.default
            agenixModule
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit
                    util
                    system
                    hosts
                    ;
                };
                sharedModules = [ hostSpec ];
              };
            }
            inputs.nvim-nix.nixosModules.default
            hostSpec
          ];
        };

        pc = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              util
              system
              hosts
              ;
          };

          modules = [
            ./hosts/pc/configuration.nix
            inputs.home-manager.nixosModules.default
            agenixModule
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit
                    util
                    system
                    hosts
                    ;
                };
                sharedModules = [ hostSpec ];
              };
            }
            hostSpec
            inputs.nvim-nix.nixosModules.default
          ];
        };

        vm-docker = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              util
              system
              hosts
              ;
          };

          modules = [
            ./hosts/vm/docker/configuration.nix
            agenixModule
            inputs.home-manager.nixosModules.default
            {
              home-manager.extraSpecialArgs = {
                inherit util system hostSpec;
              };
            }
            inputs.nvim-nix.nixosModules.default
            hostSpec
          ];
        };

        vm-router = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs util system;
          };

          modules = [
            ./hosts/vm/router/configuration.nix
            agenixModule
            hostSpec
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
          agenixModule
          hostSpec
          hosts
          ;
      });
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: rec {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.agenix-rekey.overlays.default ];
      };
      devShells.default = pkgs.mkShell {
        packages = [ pkgs.agenix-rekey ];
      };
    });
}
