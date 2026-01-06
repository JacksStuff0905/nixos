{config, lib, pkgs, util, ...}:

let
        cfg = config.fonts;

        types = {
                font = lib.types.submodule {
                        options = {
                                package = lib.mkOption {
                                        type = lib.types.nullOr lib.types.package;
                                        default = null;
                                };

                                name = lib.mkOption {
                                        type = lib.types.str;
                                };
                        };
                };
        };
in
{

        options.fonts = {
                enable = lib.mkEnableOption "Enable font management module";

                main = {
                        sans = lib.mkOption {
                                type = lib.types.listOf types.font;
                                default = [{
                                        package = pkgs.nerd-fonts.caskaydia-cove;
                                        name = "Caskaydia Cove Nerd Font";
                                }];
                        };
                        serif = lib.mkOption {
                                type = lib.types.listOf types.font;
                                default = [{
                                        package = pkgs.nerd-fonts.caskaydia-cove;
                                        name = "Caskaydia Cove Nerd Font";
                                }];
                        };
                        mono = lib.mkOption {
                                type = lib.types.listOf types.font;
                                default = [{
                                        package = pkgs.nerd-fonts.caskaydia-cove;
                                        name = "Caskaydia Cove Nerd Font Mono";
                                }];
                        };
                };

                additional = {
                        sans = lib.mkOption {
                                type = lib.types.listOf types.font;
                                default = [];
                        };
                        serif = lib.mkOption {
                                type = lib.types.listOf types.font;
                                default = [];
                        };
                        mono = lib.mkOption {
                                type = lib.types.listOf types.font;
                                default = [];
                        };
                };
        };


        config = lib.mkIf cfg.enable {
                home.packages = lib.flatten [ 
                        (builtins.map (f: lib.mkIf (f.package != null) f.package) cfg.main.sans)
                        (builtins.map (f: lib.mkIf (f.package != null) f.package) cfg.main.serif)
                        (builtins.map (f: lib.mkIf (f.package != null) f.package) cfg.main.mono)

                        (builtins.map (f: lib.mkIf (f.package != null) f.package) cfg.additional.sans)
                        (builtins.map (f: lib.mkIf (f.package != null) f.package) cfg.additional.serif)
                        (builtins.map (f: lib.mkIf (f.package != null) f.package) cfg.additional.mono)
                ];

                fonts = {
                        #enableDefaultPackages = true;

                        fontconfig = {
                                enable = true;
                                defaultFonts = let

                                in {
                                        serif = builtins.map (f: f.name) cfg.main.serif;
                                        sansSerif = builtins.map (f: f.name) cfg.main.sans;
                                        monospace = builtins.map (f: f.name) cfg.main.mono;
                                };
                        };
                };
        };
}
