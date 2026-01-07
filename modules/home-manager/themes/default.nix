{config, lib, pkgs, util, ...}:

let
        file_to_not_import = [
                "default.nix"
        ];
in
{
        options.themes = {
                enable = lib.mkEnableOption "Enable theme module";
                theme = {
                        name = lib.mkOption {
                                type = lib.types.str;
                                default = "godot";
                        };
                        
                        style = lib.mkOption {
                                type = lib.types.enum ["dark" "light"];
                                default = "dark";
                        };
                };
        };
}
