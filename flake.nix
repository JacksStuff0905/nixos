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
                  hostName = mkOption {
                    type = str;
                    description = "The hostname of the host";
                  };
                  networking = {
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
                        };
                        ip = mkOption {
                          type = str;
                          description = "The mesh vpn ip address of this host";
                        };
                        endpoint = mkOption {
                          type = nullOr str;
                          description = "The mesh vpn endpoint of this host (or null)";
                          default = null;
                        };
                        listenPort = mkOption {
                          type = int;
                          default = 51820;
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
                  domain = mkOption {
                    type = nullOr str;
                    description = "The domain of the host";
                    default = null;
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
              indexed = lib.imap0 (idx: h: {
                inherit idx;
                key = h.host.hostPubKey;
              }) (builtins.attrValues hosts);
              found = lib.findFirst (x: x.key == config.host.hostPubKey) null indexed;
              primary_id = toString found.idx;
            in
            {
              environment.sessionVariables.AGENIX_REKEY_PRIMARY_IDENTITY = primary_id;
              environment.sessionVariables.AGENIX_REKEY_PRIMARY_IDENTITY_ONLY = true;

              age.rekey = lib.mkMerge [
                (lib.mkIf (config.host ? hostPubKey && config.host.hostPubKey != null) {
                  hostPubkey = config.host.hostPubKey;
                })
                {
                  masterIdentities =
                    lib.mapAttrsToList
                      (n: h: {
                        identity = "${h.host.user.keyPath}";
                        pubkey = "${h.host.user.pubKey}";
                      })
                      (
                        lib.filterAttrs (
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
                        ) hosts
                      );

                  storageMode = "local";

                  localStorageDir = ./. + "/secrets/rekeyed/${config.host.hostName}";
                }
              ];
            };
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
