{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tools.cli.dev-flake-init;
in
{
  options.tools.cli.dev-flake-init = {
    enable = lib.mkEnableOption "Enable dev-flake-init module";
    flake-preset = lib.mkOption {
      type = lib.types.str;
      default = ''
        {
          description = \"$DEV_FLAKE_NAME dev shell\";

          inputs = {
            nixpkgs.url = \"github:nixos/nixpkgs/nixos-unstable\";

            # TOOLS
          };

          outputs =
            {
              self,
              nixpkgs,
              ...
            }@inputs:
            let
              system = \"x86_64-linux\";
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
              lib = pkgs.lib;
            in
            {
              devShells.''\\''\${system}.default = pkgs.mkShell {
                buildInputs = with pkgs; [
                  # PACKAGES
                ];

                shellHook = ''\''
                  echo \"$DEV_FLAKE_NAME development env loaded.\"
                  exec zsh
                ''\'';
              };
            };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "dev-flake-init" ''
        DEV_FLAKE_NAME="$1"
        echo "${cfg.flake-preset}" > ./flake.nix
        echo "Dev flake created (./flake.nix)"
      '')
    ];
  };
}
