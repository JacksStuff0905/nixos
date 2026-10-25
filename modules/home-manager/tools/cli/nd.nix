{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tools.cli.nd;
in
{
  # Shorthand for 'z *project* && nix develop'

  options.tools.cli.nd = {
    enable = lib.mkEnableOption "nd";
    allowUnfree = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "nd" (''
        project="$1"
        dir="$(zoxide query "$project")"
        cd "$dir" && nix develop
      ''))
    ];
  };
}
