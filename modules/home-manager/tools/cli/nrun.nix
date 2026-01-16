{config, lib, pkgs, ...}:
let
        cfg = config.tools.cli.nrun;
in
{
	options.tools.cli.nrun = {
		enable = lib.mkEnableOption "Enable nrun module";
                allowUnfree = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                };
	};

	config = lib.mkIf cfg.enable {
                home.packages = [
                        (pkgs.writeShellScriptBin "nrun" (''
                                package="$1"
                                if [[ -z "$package" ]]; then
                                        echo "No package specified, aborting..."
                                        exit 1
                                fi
                                echo "Running $package in a sandbox..."
                                '' + 
                                (if (cfg.allowUnfree) then
                                ''
                                NIXPKGS_ALLOW_UNFREE=1 nix run --impure nixpkgs#"$package"''
                                else
                                ''
                                nix run nixpkgs#"$package"
                                ''))
                        )
                 ];
	};
}
