{
  description = "Main NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

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

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
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
        types = import ./util/types.nix { inherit pkgs; };
        tools = import ./util/tools.nix { inherit pkgs; };
      };

      hostSpec = (
        { config, lib, ... }:
        {
          options.host = lib.mkOption {
            description = "This host's specification";
            type = util.types.host config;
          };

          config.host = {
            user.keyPath =
              if config.host.user.pubKey != null then
                (lib.mkDefault "${config.host.user.home}/.ssh/id_ed25519")
              else
                null;
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

          config =
            let
              masterHosts = lib.filterAttrs (
                n: h:
                (
                  h ? host
                  && h.host ? user
                  && h.host.user ? pubKey
                  && h.host.user.pubKey != null
                  && h.host.user ? keyPath
                  && h.host.user.keyPath != null
                  && h.host ? isDev
                  && h.host.isDev
                )
              ) common.hosts;
              indexed = lib.imap0 (idx: h: {
                inherit idx;
                key = h.host.hostPubKey;
              }) (builtins.attrValues masterHosts);
              found = lib.findFirst (x: x.key == config.host.hostPubKey) null indexed;
              primary_id = if (found == null || !(found ? idx)) then null else (toString found.idx);
            in
            {
              environment.sessionVariables.AGENIX_REKEY_PRIMARY_IDENTITY = config.host.user.pubKey;
              #environment.sessionVariables.AGENIX_REKEY_PRIMARY_IDENTITY_ONLY = true;

              age.rekey = lib.mkMerge [
                (lib.mkIf (config.host ? hostPubKey && config.host.hostPubKey != null) {
                  hostPubkey = config.host.hostPubKey;
                })
                {
                  masterIdentities = lib.mapAttrsToList (n: h: {
                    identity = "${h.host.user.keyPath}";
                    pubkey = "${h.host.user.pubKey}";
                  }) masterHosts;

                  storageMode = "local";

                  localStorageDir = ./. + "/secrets/rekeyed/${config.host.hostName}";
                }
              ];
            };
        }
      );

      nixosHosts = lib.mapAttrs (name: cfg: cfg.config) self.nixosConfigurations;

      externalHosts = lib.mapAttrs (name: h: {
        host =
          (lib.evalModules {
            modules = [
              { config.host = h; }
              hostSpec
            ];
          }).config.host;
      }) (import ./hosts/external.nix { inherit pkgs; });

      common = {
        inherit nixosHosts externalHosts;
        hosts = nixosHosts // externalHosts;
      };
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
              common
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
                    common
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
              common
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
                    common
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
              common
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
          common
          ;
      });
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: rec {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.agenix-rekey.overlays.default ];
      };
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.agenix-rekey
          pkgs.ssh-to-age
          (pkgs.writeShellScriptBin "agenix-batch-encrypt-txt" "
for file in $(pwd)/*.txt; do agenix edit -i \"$file\" \"\${file%\".txt\"}.age\"; done
          ")
        ];
      };
    });
}
